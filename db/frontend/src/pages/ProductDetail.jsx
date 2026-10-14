export default function ProductDetail({ product }) {
  if (!product) {
    return (
      <div className="rounded-[28px] glass-panel p-6 shadow-panel">
        <p className="font-display text-2xl text-ink">Product Detail</p>
        <p className="mt-4 text-sm text-slate-600">
          Select a recommended item or any catalog product to inspect the live payload.
        </p>
      </div>
    );
  }

  const hasMatchScore = typeof product.match_score !== "undefined" && product.match_score !== null;
  const availability = typeof product.stock !== "undefined"
    ? `${product.stock} units`
    : product.in_stock
      ? "Available"
      : "Out of stock";

  return (
    <div className="rounded-[28px] glass-panel p-6 shadow-panel">
      <p className="font-display text-2xl text-ink">{product.name}</p>
      <p className="mt-2 text-sm uppercase tracking-[0.2em] text-slate-500">{product.brand || "Unbranded"}</p>
      {product.display_label ? (
        <p className="mt-4 inline-flex rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-amber-800">
          {product.display_label}
        </p>
      ) : null}

      <dl className="mt-6 grid gap-4 sm:grid-cols-2">
        <div className={`rounded-2xl px-4 py-4 ${hasMatchScore ? "bg-slate-900 text-white" : "bg-tide text-white"}`}>
          <dt className={`text-xs uppercase tracking-[0.2em] ${hasMatchScore ? "text-slate-300" : "text-emerald-100"}`}>
            {hasMatchScore ? "Match score" : "Availability"}
          </dt>
          <dd className="mt-2 font-display text-3xl">
            {hasMatchScore ? `${(Number(product.match_score) * 100).toFixed(1)}%` : availability}
          </dd>
        </div>
        <div className="rounded-2xl bg-white px-4 py-4">
          <dt className="text-xs uppercase tracking-[0.2em] text-slate-500">Price</dt>
          <dd className="mt-2 font-display text-3xl text-ink">Rs. {Number(product.price).toLocaleString()}</dd>
        </div>
      </dl>

      <dl className="mt-4 grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl bg-white px-4 py-4">
          <dt className="text-xs uppercase tracking-[0.2em] text-slate-500">Category</dt>
          <dd className="mt-2 text-lg font-semibold text-ink">{product.category || "Unspecified"}</dd>
        </div>
        <div className="rounded-2xl bg-white px-4 py-4">
          <dt className="text-xs uppercase tracking-[0.2em] text-slate-500">Status</dt>
          <dd className="mt-2 text-lg font-semibold text-ink">{availability}</dd>
        </div>
      </dl>

      {product.rec_type ? (
        <dl className="mt-4 grid gap-4 sm:grid-cols-2">
          <div className="rounded-2xl bg-white px-4 py-4">
            <dt className="text-xs uppercase tracking-[0.2em] text-slate-500">Recommendation Type</dt>
            <dd className="mt-2 text-lg font-semibold capitalize text-ink">{product.rec_type}</dd>
          </div>
          <div className="rounded-2xl bg-white px-4 py-4">
            <dt className="text-xs uppercase tracking-[0.2em] text-slate-500">Pair Type</dt>
            <dd className="mt-2 text-lg font-semibold capitalize text-ink">{product.pair_type || "similar"}</dd>
          </div>
        </dl>
      ) : null}

      <div className="mt-6 rounded-[24px] bg-white/80 p-4">
        <p className="text-xs uppercase tracking-[0.22em] text-slate-500">Live payload</p>
        <pre className="mt-3 overflow-auto rounded-2xl bg-slate-950 p-4 text-xs text-slate-100">
          {JSON.stringify(product, null, 2)}
        </pre>
      </div>
    </div>
  );
}
