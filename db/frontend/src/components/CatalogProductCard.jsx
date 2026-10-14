export default function CatalogProductCard({ product, onBuy, buying, onSelect, isSelected }) {
  const inStock = Boolean(product.in_stock);

  return (
    <article
      className={`rounded-[28px] glass-panel p-5 shadow-panel transition hover:-translate-y-1 cursor-pointer ${
        isSelected ? "ring-2 ring-tide ring-offset-2 ring-offset-[#f8fafc]" : ""
      }`}
      onClick={() => onSelect?.(product)}
      role="button"
      tabIndex={0}
      onKeyDown={(event) => {
        if (event.key === "Enter" || event.key === " ") {
          onSelect?.(product);
        }
      }}
    >
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="font-display text-xl text-ink">{product.name}</p>
          <p className="mt-1 text-sm uppercase tracking-[0.18em] text-slate-500">
            {product.brand || "Independent brand"}
          </p>
        </div>
        <span
          className={`rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] ${
            inStock ? "bg-emerald-100 text-emerald-800" : "bg-slate-200 text-slate-500"
          }`}
        >
          {inStock ? `${product.stock} in stock` : "Sold out"}
        </span>
      </div>

      <div className="mt-5 flex items-end justify-between gap-4">
        <div>
          <p className="text-sm text-slate-500">{product.category}</p>
          <p className="font-display text-2xl text-ink">Rs. {Number(product.price).toLocaleString()}</p>
        </div>
        <button
          onClick={(event) => {
            event.stopPropagation();
            onBuy(product.product_id);
          }}
          disabled={!inStock || buying}
          className="rounded-full border border-ink px-4 py-2 text-sm font-semibold text-ink transition hover:bg-ink hover:text-white disabled:cursor-not-allowed disabled:border-slate-300 disabled:text-slate-400"
        >
          {buying ? "Processing..." : inStock ? "Buy Now" : "Sold Out"}
        </button>
      </div>
    </article>
  );
}
