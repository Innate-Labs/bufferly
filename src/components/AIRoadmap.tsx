import { Bot, Boxes, KeyRound } from "lucide-react";

const roadmap = [
  {
    icon: Boxes,
    title: "AI-ready context packs",
    description: "把相关剪贴板片段整理成 Markdown 或 JSON，再交给 AI 编程工具。",
  },
  {
    icon: Bot,
    title: "Local MCP tools",
    description: "为 Claude Code、Cursor、Codex 暴露用户可控的本地剪贴板工具。",
  },
  {
    icon: KeyRound,
    title: "Encrypted history",
    description: "使用 Keychain 管理密钥，为本地 SQLite 历史增加加密层。",
  },
];

export default function AIRoadmap() {
  return (
    <section className="border-b border-[#d9dde2] bg-white py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="grid gap-10 lg:grid-cols-[0.8fr_1.2fr] lg:items-start">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#0a84ff]">
              Roadmap
            </p>
            <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.03em] text-[#141922] sm:text-5xl">
              AI 工作流会增强，但不会改变本地优先。
            </h2>
            <p className="mt-5 text-lg leading-8 text-[#5f6b7a]">
              Bufferly 的 AI 方向不是替你把数据上传到云端，而是帮你更可控地整理、选择、交给 AI。
            </p>
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            {roadmap.map((item) => (
              <article key={item.title} className="rounded-2xl border border-[#d7dde5] bg-[#f8f9fa] p-5">
                <div className="mb-5 flex h-11 w-11 items-center justify-center rounded-xl border border-[#d7dde5] bg-white text-[#11161d]">
                  <item.icon size={21} />
                </div>
                <h3 className="text-lg font-semibold text-[#18202a]">{item.title}</h3>
                <p className="mt-3 text-sm leading-6 text-[#667382]">{item.description}</p>
                <span className="mt-5 inline-flex rounded-full bg-[#eef2f6] px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-[#65717f]">
                  planned
                </span>
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
