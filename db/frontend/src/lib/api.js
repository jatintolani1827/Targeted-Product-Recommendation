const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:5000/api";

async function request(path, options = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {})
    },
    ...options
  });

  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("application/json")
    ? await response.json()
    : await response.text();

  if (!response.ok) {
    const message = typeof payload === "string" ? payload : payload.error || "Request failed";
    throw new Error(message);
  }

  return payload;
}

export const api = {
  getUsers: () => request("/users"),
  getCategories: () => request("/categories"),
  getProducts: () => request("/products"),
  getPurchaseHistory: (userId) => request(`/purchase-history?user_id=${userId}`),
  getRecommendations: (userId) => request(`/recommendations?user_id=${userId}`),
  getAdminRecommendations: () => request("/admin/recommendations"),
  getAdminOrders: () => request("/admin/orders"),
  deleteAdminProduct: (productId) =>
    request(`/admin/products/${productId}`, {
      method: "DELETE"
    }),
  deleteAdminOrderEntry: (detailId) =>
    request(`/admin/orders/${detailId}`, {
      method: "DELETE"
    }),
  getRfmStats: () => request("/rfm-stats"),
  createProduct: (payload) =>
    request("/products", {
      method: "POST",
      body: JSON.stringify(payload)
    }),
  purchase: (payload) =>
    request("/purchase", {
      method: "POST",
      body: JSON.stringify(payload)
    }),
  refreshRfm: () =>
    request("/rfm-refresh", {
      method: "POST"
    })
};
