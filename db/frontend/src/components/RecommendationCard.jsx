export default function RecommendationCard({ item, onBuy, buying, onSelect, isSelected }) {
  const inStock = Number(item.stock) > 0;

  return (
    <article
      className={`animate-floatUp rounded-[28px] glass-panel p-5 shadow-panel transition hover:-translate-y-1 cursor-pointer ${
        isSelected ? "ring-2 ring-tide ring-offset-2 ring-offset-[#f8fafc]" : ""
      }`}
      onClick={() => onSelect?.(item)}
      role="button"
      tabIndex={0}
      onKeyDown={(event) => {
        if (event.key === "Enter" || event.key === " ") {
          onSelect?.(item);
        }
      }}
    >
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="font-display text-xl text-ink">{item.name}</p>
          <p className="mt-1 text-sm uppercase tracking-[0.18em] text-slate-500">{item.brand || "Independent brand"}</p>
          {item.display_label ? (
            <p className="mt-3 inline-flex rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-amber-800">
              {item.display_label}
            </p>
          ) : null}
        </div>
        <span className="animate-pulseBadge rounded-full bg-tide px-3 py-1 text-sm font-semibold text-white">
          {(Number(item.match_score) * 100).toFixed(1)}%
        </span>
      </div>

      <div className="mt-6 flex items-end justify-between gap-4">
        <div>
          <p className="text-sm text-slate-500">Price</p>
          <p className="font-display text-2xl text-ink">Rs. {Number(item.price).toLocaleString()}</p>
        </div>
        <button
          onClick={(event) => {
            event.stopPropagation();
            onBuy(item.product_id);
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
