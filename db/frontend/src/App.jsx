import { useState } from "react";
import AdminDashboard from "./pages/AdminDashboard";
import UserPortal from "./pages/UserPortal";

const tabs = [
  { id: "admin", label: "Admin Dashboard" },
  { id: "customer", label: "Customer Portal" }
];

export default function App() {
  const [activeTab, setActiveTab] = useState("admin");

  return (
    <main className="mx-auto min-h-screen max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <section className="relative overflow-hidden rounded-[36px] border border-white/40 bg-white/70 px-6 py-8 shadow-panel sm:px-8">
        <div className="mesh-accent absolute inset-0" />
        <div className="relative flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div className="max-w-3xl">
            <p className="text-sm uppercase tracking-[0.35em] text-slate-500">Targeted Product Recommendation Engine</p>
            <h1 className="mt-3 font-display text-4xl leading-tight text-ink sm:text-6xl">
              Cold-start recommendations with SQL intelligence and ACID-safe commerce.
            </h1>
            <p className="mt-4 max-w-2xl text-base text-slate-600 sm:text-lg">
              This interface fronts a PostgreSQL-first system that combines Recursive CTEs, RFM scoring,
              market basket analysis, queue-driven automation, and a Flask API into one demonstrable project.
            </p>
          </div>

          <div className="flex flex-wrap gap-3">
            {tabs.map((tab) => {
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setActiveTab(tab.id)}
                  className={`rounded-full px-5 py-3 text-sm font-semibold transition ${
                    isActive
                      ? "bg-ink text-white"
                      : "border border-slate-300 bg-white/80 text-ink hover:border-ink"
                  }`}
                >
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>
      </section>

      <section className="mt-8">
        {activeTab === "admin" ? <AdminDashboard /> : <UserPortal />}
      </section>
    </main>
  );
}

