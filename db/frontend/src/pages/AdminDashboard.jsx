import { useEffect, useState } from "react";
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import ProductForm from "../components/ProductForm";
import { api } from "../lib/api";

const chartPalette = ["#0f766e", "#f97316", "#9f1239", "#334155"];

export default function AdminDashboard() {
  const [categories, setCategories] = useState([]);
  const [recommendations, setRecommendations] = useState([]);
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [rfmStats, setRfmStats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [creatingProduct, setCreatingProduct] = useState(false);
  const [deletingProductId, setDeletingProductId] = useState(null);
  const [deletingDetailId, setDeletingDetailId] = useState(null);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function loadDashboard() {
    setLoading(true);
    setError("");
    try {
      const [categoryData, recommendationData, productData, orderData, statsData] = await Promise.all([
        api.getCategories(),
        api.getAdminRecommendations(),
        api.getProducts(),
        api.getAdminOrders(),
        api.getRfmStats()
      ]);
      setCategories(categoryData);
      setRecommendations(recommendationData);
      setProducts(productData);
      setOrders(orderData);
      setRfmStats(statsData);
    } catch (loadError) {
      setError(loadError.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadDashboard();
  }, []);

  async function handleProductSubmit(payload) {
    setCreatingProduct(true);
    setMessage("");
    try {
      const response = await api.createProduct(payload);
      setMessage(`Product ${response.product_id} created. Queue worker can process it immediately.`);
      await loadDashboard();
    } finally {
      setCreatingProduct(false);
    }
  }

  async function handleRefreshRfm() {
    try {
      await api.refreshRfm();
      await loadDashboard();
      setMessage("RFM scores refreshed.");
    } catch (refreshError) {
      setError(refreshError.message);
    }
  }

  async function handleDeleteOrderEntry(detailId) {
    const confirmed = window.confirm("Delete this order-history entry and restore its stock?");
    if (!confirmed) {
      return;
    }

    try {
      setDeletingDetailId(detailId);
      setError("");
      const response = await api.deleteAdminOrderEntry(detailId);
      setMessage(`Deleted order-history entry ${response.detail_id} and restored stock.`);
      await loadDashboard();
    } catch (deleteError) {
      setError(deleteError.message);
    } finally {
      setDeletingDetailId(null);
    }
  }

  async function handleDeleteProduct(productId, productName) {
    const confirmed = window.confirm(
      `Delete product "${productName}"? This also removes its order-history lines and refreshes impacted users.`
    );
    if (!confirmed) {
      return;
    }

    try {
      setDeletingProductId(productId);
      setError("");
      const response = await api.deleteAdminProduct(productId);
      setMessage(`Deleted product ${response.product_name} and cleaned up dependent history.`);
      await loadDashboard();
    } catch (deleteError) {
      setError(deleteError.message);
    } finally {
      setDeletingProductId(null);
    }
  }

  return (
    <div className="grid gap-6">
      <div className="grid gap-6 xl:grid-cols-[1.15fr_0.85fr]">
        <div className="grid gap-6">
          <ProductForm
            categories={categories}
            onSubmit={handleProductSubmit}
            loading={creatingProduct}
            message={message}
          />

        </div>

        <div className="grid gap-6">
          <section className="rounded-[28px] glass-panel p-6 shadow-panel">
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="font-display text-2xl text-ink">RFM Tier Distribution</p>
                <p className="text-sm text-slate-600">Materialized-view summary used by the recommendation engine.</p>
              </div>
              <button
                onClick={handleRefreshRfm}
                className="rounded-full bg-tide px-4 py-2 text-sm font-semibold text-white transition hover:opacity-90"
              >
                Refresh RFM
              </button>
            </div>
            <div className="mt-6 h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={rfmStats}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#cbd5e1" />
                  <XAxis dataKey="rfm_tier" stroke="#475569" />
                  <YAxis stroke="#475569" allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="user_count" radius={[14, 14, 0, 0]}>
                    {rfmStats.map((entry, index) => (
                      <Cell key={entry.rfm_tier} fill={chartPalette[index % chartPalette.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </section>


        </div>
      </div>

      <section className="rounded-[28px] glass-panel p-6 shadow-panel">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="font-display text-2xl text-ink">Recent Targeting Output</p>
            <p className="text-sm text-slate-600">
              Latest user-product matches produced by the stored procedure.
            </p>
          </div>
          <button
            onClick={loadDashboard}
            className="rounded-full border border-ink px-4 py-2 text-sm font-semibold text-ink transition hover:bg-ink hover:text-white"
          >
            Refresh
          </button>
        </div>

        <div className="mt-6 overflow-x-auto max-h-[500px] overflow-y-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-slate-500">
              <tr>
                <th className="pb-3">User</th>
                <th className="pb-3">Tier</th>
                <th className="pb-3">Product</th>
                <th className="pb-3">Score</th>
                <th className="pb-3">Generated</th>
              </tr>
            </thead>
            <tbody>
              {recommendations.map((item) => (
                <tr key={item.rec_id} className="border-t border-slate-200/70">
                  <td className="py-3">
                    <p className="font-semibold text-ink">{item.full_name}</p>
                    <p className="text-xs text-slate-500">{item.email}</p>
                  </td>
                  <td className="py-3 capitalize">{item.rfm_tier}</td>
                  <td className="py-3">{item.product_name}</td>
                  <td className="py-3 font-semibold text-tide">{(Number(item.match_score) * 100).toFixed(1)}%</td>
                  <td className="py-3 text-xs text-slate-500">{new Date(item.generated_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {!loading && !recommendations.length ? (
            <p className="py-6 text-sm text-slate-500">No recommendations yet. Add a product and run the queue worker.</p>
          ) : null}
        </div>
      </section>

      <section className="rounded-[28px] glass-panel p-6 shadow-panel">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="font-display text-2xl text-ink">All Products</p>
            <p className="text-sm text-slate-600">Current catalog inventory available across the platform.</p>
          </div>
          <span className="rounded-full bg-ink px-3 py-1 text-xs uppercase tracking-[0.24em] text-white">
            {products.length} products
          </span>
        </div>

        <div className="mt-6 overflow-x-auto max-h-[500px] overflow-y-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-slate-500">
              <tr>
                <th className="pb-3">Product</th>
                <th className="pb-3">Category</th>
                <th className="pb-3">Price</th>
                <th className="pb-3">Stock</th>
                <th className="pb-3">Created</th>
                <th className="pb-3">Action</th>
              </tr>
            </thead>
            <tbody>
              {products.map((product) => (
                <tr key={product.product_id} className="border-t border-slate-200/70">
                  <td className="py-3">
                    <p className="font-semibold text-ink">{product.name}</p>
                    <p className="text-xs text-slate-500">{product.brand || "Unbranded"} · #{product.product_id}</p>
                  </td>
                  <td className="py-3">{product.category}</td>
                  <td className="py-3 font-semibold text-tide">Rs. {Number(product.price).toLocaleString()}</td>
                  <td className="py-3">{product.stock}</td>
                  <td className="py-3 text-xs text-slate-500">{new Date(product.created_at).toLocaleString()}</td>
                  <td className="py-3">
                    <button
                      onClick={() => handleDeleteProduct(product.product_id, product.name)}
                      disabled={deletingProductId === product.product_id}
                      className="rounded-full bg-rose-600 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      {deletingProductId === product.product_id ? "Deleting..." : "Delete"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="rounded-[28px] glass-panel p-6 shadow-panel">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="font-display text-2xl text-ink">User Order History</p>
            <p className="text-sm text-slate-600">Delete individual order-history entries and restore stock safely.</p>
          </div>
          <span className="rounded-full bg-berry px-3 py-1 text-xs uppercase tracking-[0.24em] text-white">
            Admin Controls
          </span>
        </div>

        <div className="mt-6 overflow-x-auto max-h-[500px] overflow-y-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-slate-500">
              <tr>
                <th className="pb-3">User</th>
                <th className="pb-3">Order</th>
                <th className="pb-3">Product</th>
                <th className="pb-3">Qty</th>
                <th className="pb-3">Total</th>
                <th className="pb-3">Date</th>
                <th className="pb-3">Action</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((entry) => (
                <tr key={entry.detail_id} className="border-t border-slate-200/70">
                  <td className="py-3">
                    <p className="font-semibold text-ink">{entry.full_name}</p>
                    <p className="text-xs text-slate-500">{entry.email}</p>
                  </td>
                  <td className="py-3">
                    <p className="font-semibold text-ink">#{entry.order_id}</p>
                    <p className="text-xs text-slate-500">Entry #{entry.detail_id}</p>
                  </td>
                  <td className="py-3">
                    <p className="font-semibold text-ink">{entry.product_name}</p>
                    <p className="text-xs text-slate-500">{entry.brand || "Unbranded"} · {entry.category}</p>
                  </td>
                  <td className="py-3">{entry.quantity}</td>
                  <td className="py-3 font-semibold text-tide">Rs. {Number(entry.total_amt).toLocaleString()}</td>
                  <td className="py-3 text-xs text-slate-500">{new Date(entry.created_at).toLocaleString()}</td>
                  <td className="py-3">
                    <button
                      onClick={() => handleDeleteOrderEntry(entry.detail_id)}
                      disabled={deletingDetailId === entry.detail_id}
                      className="rounded-full bg-rose-600 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      {deletingDetailId === entry.detail_id ? "Deleting..." : "Delete"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!loading && !orders.length ? (
            <p className="py-6 text-sm text-slate-500">No order-history entries found.</p>
          ) : null}
        </div>
      </section>

      {error ? <p className="rounded-2xl bg-rose-100 px-4 py-3 text-sm text-rose-700">{error}</p> : null}
    </div>
  );
}
