import { useDeferredValue, useEffect, useState } from "react";
import ProductDetail from "./ProductDetail";
import RecommendationCard from "../components/RecommendationCard";
import CatalogProductCard from "../components/CatalogProductCard";
import { api } from "../lib/api";

export default function UserPortal() {
  const [users, setUsers] = useState([]);
  const [selectedUserId, setSelectedUserId] = useState("");
  const [recommendations, setRecommendations] = useState([]);
  const [products, setProducts] = useState([]);
  const [purchaseHistory, setPurchaseHistory] = useState([]);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [buyingProductId, setBuyingProductId] = useState(null);
  const [flashSaleProductId, setFlashSaleProductId] = useState("");
  const [flashSaleResults, setFlashSaleResults] = useState(null);
  const [catalogQuery, setCatalogQuery] = useState("");
  const [error, setError] = useState("");
  const deferredCatalogQuery = useDeferredValue(catalogQuery);

  useEffect(() => {
    api
      .getUsers()
      .then((data) => {
        setUsers(data);
        if (data.length) {
          setSelectedUserId(String(data[0].user_id));
        }
      })
      .catch((usersError) => setError(usersError.message));
  }, []);

  async function loadCustomerData(userId, focusProductId = null) {
    const [recommendationData, productData, historyData] = await Promise.all([
      api.getRecommendations(userId),
      api.getProducts(),
      api.getPurchaseHistory(userId)
    ]);

    setRecommendations(recommendationData);
    setProducts(productData);
    setPurchaseHistory(historyData);

    const preferredProductId = focusProductId || selectedProduct?.product_id;
    const focusProduct =
      recommendationData.find((item) => item.product_id === preferredProductId) ||
      productData.find((item) => item.product_id === preferredProductId) ||
      recommendationData[0] ||
      productData[0] ||
      null;

    setSelectedProduct(focusProduct);
  }

  useEffect(() => {
    if (!selectedUserId) {
      return;
    }
    loadCustomerData(selectedUserId).catch((loadError) => setError(loadError.message));
  }, [selectedUserId]);

  async function handleBuy(productId) {
    try {
      setError("");
      setBuyingProductId(productId);
      await api.purchase({
        user_id: Number(selectedUserId),
        product_id: productId,
        quantity: 1
      });
      await loadCustomerData(selectedUserId, productId);
    } catch (buyError) {
      setError(buyError.message);
    } finally {
      setBuyingProductId(null);
    }
  }

  async function runFlashSale() {
    if (!flashSaleProductId || !selectedUserId) {
      setError("Pick a user and provide a product id for the flash sale.");
      return;
    }

    setError("");
    const payload = {
      user_id: Number(selectedUserId),
      product_id: Number(flashSaleProductId),
      quantity: 1
    };

    const responses = await Promise.allSettled(
      Array.from({ length: 50 }, () => api.purchase(payload))
    );

    const successes = responses.filter((result) => result.status === "fulfilled").length;
    const failures = responses.length - successes;
    setFlashSaleResults({ successes, failures });
    await loadCustomerData(selectedUserId, Number(flashSaleProductId));
  }

  const filteredProducts = products.filter((product) => {
    const query = deferredCatalogQuery.trim().toLowerCase();
    if (!query) {
      return true;
    }

    const haystack = [product.name, product.brand, product.category]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();

    return haystack.includes(query);
  });

  return (
    <div className="grid gap-6">
      {error ? <p className="rounded-2xl bg-rose-100 px-4 py-3 text-sm text-rose-700">{error}</p> : null}

      <section className="rounded-[28px] glass-panel p-6 shadow-panel">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="font-display text-2xl text-ink">Recommended for You</p>
            <p className="text-sm text-slate-600">Customer-side view backed by targeted recommendations.</p>
          </div>
          <select
            className="rounded-full border border-slate-300 bg-white/90 px-4 py-2 text-sm font-semibold text-ink outline-none transition focus:border-tide"
            value={selectedUserId}
            onChange={(event) => setSelectedUserId(event.target.value)}
          >
            {users.map((user) => (
              <option key={user.user_id} value={user.user_id}>
                {user.full_name} · {user.rfm_tier}
              </option>
            ))}
          </select>
        </div>

        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 max-h-[500px] overflow-y-auto pr-2">
          {recommendations.map((item) => (
            <div
              key={item.product_id}
              className="text-left"
            >
              <RecommendationCard
                item={item}
                onBuy={handleBuy}
                buying={buyingProductId === item.product_id}
                onSelect={setSelectedProduct}
                isSelected={selectedProduct?.product_id === item.product_id}
              />
            </div>
          ))}
          {!recommendations.length ? (
            <p className="rounded-2xl bg-white/70 px-4 py-5 text-sm text-slate-600">
              No active recommendations right now. The user can still browse and buy from the full product catalog below.
            </p>
          ) : null}
        </div>
      </section>

      <ProductDetail product={selectedProduct} />

      <section className="rounded-[28px] glass-panel p-6 shadow-panel">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="font-display text-2xl text-ink">Shop All Products</p>
            <p className="text-sm text-slate-600">Customers can purchase any live product, not just recommended items.</p>
          </div>
          <input
            className="rounded-full border border-slate-300 bg-white/90 px-4 py-2 text-sm text-ink outline-none transition focus:border-ember"
            placeholder="Search name, brand, category"
            value={catalogQuery}
            onChange={(event) => setCatalogQuery(event.target.value)}
          />
        </div>

        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 max-h-[500px] overflow-y-auto pr-2">
          {filteredProducts.map((product) => (
            <CatalogProductCard
              key={product.product_id}
              product={product}
              onBuy={handleBuy}
              buying={buyingProductId === product.product_id}
              onSelect={setSelectedProduct}
              isSelected={selectedProduct?.product_id === product.product_id}
            />
          ))}
          {!filteredProducts.length ? (
            <p className="rounded-2xl bg-white/70 px-4 py-5 text-sm text-slate-600">
              No products match the current search.
            </p>
          ) : null}
        </div>
      </section>

      <section className="rounded-[28px] glass-panel p-6 shadow-panel">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="font-display text-2xl text-ink">Purchase History</p>
            <p className="text-sm text-slate-600">Recent orders for the selected user.</p>
          </div>
          <span className="rounded-full bg-ink px-3 py-1 text-xs uppercase tracking-[0.22em] text-white">
            {purchaseHistory.length} items
          </span>
        </div>

        <div className="mt-6 overflow-x-auto max-h-[500px] overflow-y-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-slate-500">
              <tr>
                <th className="pb-3">Order</th>
                <th className="pb-3">Product</th>
                <th className="pb-3">Qty</th>
                <th className="pb-3">Total</th>
                <th className="pb-3">Date</th>
              </tr>
            </thead>
            <tbody>
              {purchaseHistory.map((entry) => (
                <tr key={`${entry.order_id}-${entry.product_id}`} className="border-t border-slate-200/70">
                  <td className="py-3 font-semibold text-ink">#{entry.order_id}</td>
                  <td className="py-3">
                    <p className="font-semibold text-ink">{entry.name}</p>
                    <p className="text-xs text-slate-500">{entry.brand || "Unbranded"} · {entry.category}</p>
                  </td>
                  <td className="py-3">{entry.quantity}</td>
                  <td className="py-3 font-semibold text-tide">Rs. {Number(entry.total_amt).toLocaleString()}</td>
                  <td className="py-3 text-xs text-slate-500">{new Date(entry.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {!purchaseHistory.length ? (
            <p className="py-6 text-sm text-slate-500">No orders yet for this user.</p>
          ) : null}
        </div>
      </section>

      <section className="rounded-[28px] glass-panel p-6 shadow-panel">
        <p className="font-display text-2xl text-ink">Flash Sale ACID Demo</p>
        <p className="mt-2 text-sm text-slate-600">
          Use a product with stock = 1 to prove row-level locking prevents overselling.
        </p>

        <div className="mt-5 grid gap-4 md:grid-cols-[1fr_auto]">
          <input
            className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-berry"
            placeholder="Product ID to stress test"
            value={flashSaleProductId}
            onChange={(event) => setFlashSaleProductId(event.target.value)}
          />
          <button
            onClick={runFlashSale}
            className="rounded-full bg-berry px-5 py-3 text-sm font-semibold text-white transition hover:opacity-90"
          >
            Fire 50 Concurrent Purchases
          </button>
        </div>

        {flashSaleResults ? (
          <div className="mt-5 grid gap-4 sm:grid-cols-2">
            <div className="rounded-[24px] bg-emerald-50 p-4">
              <p className="text-xs uppercase tracking-[0.2em] text-emerald-700">Successful purchases</p>
              <p className="mt-2 font-display text-4xl text-emerald-800">{flashSaleResults.successes}</p>
            </div>
            <div className="rounded-[24px] bg-amber-50 p-4">
              <p className="text-xs uppercase tracking-[0.2em] text-amber-700">Rolled back safely</p>
              <p className="mt-2 font-display text-4xl text-amber-800">{flashSaleResults.failures}</p>
            </div>
          </div>
        ) : null}
      </section>
    </div>
  );
}
