import { useEffect, useState } from "react";

const subclassLabels = {
  electronics: "Electronics",
  apparel: "Apparel",
  accessories: "Accessories",
  furniture: "Furniture",
  personal_care: "Personal Care",
  "": "General"
};

const defaultForm = {
  name: "",
  price: "",
  category_id: "",
  brand: "",
  stock: "0",
  attributes: "{\n  \"color\": \"black\"\n}",
  subclass: "",
  warranty_months: "24",
  power_watts: "5",
  size: "M",
  material: "cotton"
};

export default function ProductForm({ categories, onSubmit, loading, message }) {
  const [form, setForm] = useState(defaultForm);
  const [error, setError] = useState("");
  const leafCategories = categories.filter((category) => category.is_leaf);
  const selectedCategory =
    leafCategories.find((category) => String(category.category_id) === form.category_id) || leafCategories[0] || null;
  const availableSubclasses =
    selectedCategory?.allowed_subclasses?.length ? selectedCategory.allowed_subclasses : [""];
  const usesSizeMaterial = ["apparel", "accessories", "furniture", "personal_care"].includes(form.subclass);

  useEffect(() => {
    if (!leafCategories.length) {
      return;
    }

    setForm((current) => {
      const nextCategory =
        leafCategories.find((category) => String(category.category_id) === current.category_id) || leafCategories[0];
      const nextCategoryId = String(nextCategory.category_id);
      const nextSubclasses = nextCategory.allowed_subclasses?.length ? nextCategory.allowed_subclasses : [""];
      const nextSubclass = nextSubclasses.includes(current.subclass)
        ? current.subclass
        : nextCategory.default_subclass || nextSubclasses[0] || "";

      if (current.category_id === nextCategoryId && current.subclass === nextSubclass) {
        return current;
      }

      return { ...current, category_id: nextCategoryId, subclass: nextSubclass };
    });
  }, [categories]);

  function updateField(field, value) {
    setForm((current) => ({ ...current, [field]: value }));
  }

  function handleCategoryChange(categoryId) {
    const nextCategory = leafCategories.find((category) => String(category.category_id) === categoryId);
    const nextSubclasses = nextCategory?.allowed_subclasses?.length ? nextCategory.allowed_subclasses : [""];
    const nextSubclass = nextSubclasses.includes(form.subclass)
      ? form.subclass
      : nextCategory?.default_subclass || nextSubclasses[0] || "";

    setForm((current) => ({
      ...current,
      category_id: categoryId,
      subclass: nextSubclass
    }));
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");

    try {
      const payload = {
        ...form,
        price: Number(form.price),
        stock: Number(form.stock),
        category_id: Number(form.category_id),
        attributes: JSON.parse(form.attributes || "{}")
      };

      if (form.subclass === "electronics") {
        payload.warranty_months = Number(form.warranty_months);
        payload.power_watts = Number(form.power_watts);
      }

      await onSubmit(payload);
      setForm(defaultForm);
    } catch (submitError) {
      setError(submitError.message);
    }
  }

  return (
    <form className="grid gap-4 rounded-[28px] glass-panel p-6 shadow-panel" onSubmit={handleSubmit}>
      <div className="flex items-center justify-between">
        <div>
          <p className="font-display text-2xl text-ink">Launch a New Product</p>
          <p className="text-sm text-slate-600">This insert triggers async recommendation generation automatically.</p>
        </div>
        <span className="rounded-full bg-ink px-3 py-1 text-xs uppercase tracking-[0.24em] text-white">
          Admin Flow
        </span>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <label className="grid gap-2 text-sm">
          Product Name
          <input
            className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
            value={form.name}
            onChange={(event) => updateField("name", event.target.value)}
            placeholder="Sony WH-1000XM5"
            required
          />
        </label>

        <label className="grid gap-2 text-sm">
          Brand
          <input
            className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
            value={form.brand}
            onChange={(event) => updateField("brand", event.target.value)}
            placeholder="Sony"
          />
        </label>

        <label className="grid gap-2 text-sm">
          Price
          <input
            className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
            type="number"
            min="0"
            step="0.01"
            value={form.price}
            onChange={(event) => updateField("price", event.target.value)}
            required
          />
        </label>

        <label className="grid gap-2 text-sm">
          Stock
          <input
            className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
            type="number"
            min="0"
            value={form.stock}
            onChange={(event) => updateField("stock", event.target.value)}
            required
          />
        </label>

        <label className="grid gap-2 text-sm">
          Category
          <select
            className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
            value={form.category_id}
            onChange={(event) => handleCategoryChange(event.target.value)}
          >
            {leafCategories.map((category) => (
              <option key={category.category_id} value={category.category_id}>
                {category.path || category.name}
              </option>
            ))}
          </select>
        </label>

        <label className="grid gap-2 text-sm">
          Product Type
          <select
            className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
            value={form.subclass}
            onChange={(event) => updateField("subclass", event.target.value)}
            disabled={availableSubclasses.length <= 1}
          >
            {availableSubclasses.map((subclass) => (
              <option key={subclass || "general"} value={subclass}>
                {selectedCategory?.subclass_labels?.[subclass] || subclassLabels[subclass] || "General"}
              </option>
            ))}
          </select>
        </label>
      </div>

      {form.subclass === "electronics" ? (
        <div className="grid gap-4 md:grid-cols-2">
          <label className="grid gap-2 text-sm">
            Warranty Months
            <input
              className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
              type="number"
              min="0"
              value={form.warranty_months}
              onChange={(event) => updateField("warranty_months", event.target.value)}
            />
          </label>
          <label className="grid gap-2 text-sm">
            Power Watts
            <input
              className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
              type="number"
              min="0"
              step="0.1"
              value={form.power_watts}
              onChange={(event) => updateField("power_watts", event.target.value)}
            />
          </label>
        </div>
      ) : null}

      {usesSizeMaterial ? (
        <div className="grid gap-4 md:grid-cols-2">
          <label className="grid gap-2 text-sm">
            Size
            <input
              className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
              value={form.size}
              onChange={(event) => updateField("size", event.target.value)}
            />
          </label>
          <label className="grid gap-2 text-sm">
            Material
            <input
              className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 outline-none transition focus:border-ember"
              value={form.material}
              onChange={(event) => updateField("material", event.target.value)}
            />
          </label>
        </div>
      ) : null}

      <label className="grid gap-2 text-sm">
        Attributes JSON
        <textarea
          className="min-h-36 rounded-[24px] border border-slate-200 bg-white/80 px-4 py-3 font-mono text-sm outline-none transition focus:border-ember"
          value={form.attributes}
          onChange={(event) => updateField("attributes", event.target.value)}
        />
      </label>

      {error ? <p className="rounded-2xl bg-rose-100 px-4 py-3 text-sm text-rose-700">{error}</p> : null}
      {message ? <p className="rounded-2xl bg-emerald-100 px-4 py-3 text-sm text-emerald-800">{message}</p> : null}

      <button
        type="submit"
        disabled={loading}
        className="inline-flex items-center justify-center rounded-full bg-ember px-5 py-3 font-semibold text-white transition hover:translate-y-[-1px] disabled:cursor-not-allowed disabled:opacity-60"
      >
        {loading ? "Creating Product..." : "Create Product"}
      </button>
    </form>
  );
}
