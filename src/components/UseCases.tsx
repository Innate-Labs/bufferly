import { Bot, FileJson, Shield, Terminal } from "lucide-react";

const scenarios = [
  {
    icon: Terminal,
    label: "Terminal",
    title: "刚复制过的命令，被下一段内容覆盖了",
    before: "回浏览器、文档、聊天记录里重新找。",
    after: "呼出 Bufferly，搜命令关键字，回车粘贴。",
  },
  {
    icon: Bot,
    label: "AI tools",
    title: "常用 prompt 散落在不同对话里",
    before: "每次打开旧对话复制，或临时重写一遍。",
    after: "Pin 成片段库，按关键词直接贴进 Claude、Cursor、Codex。",
  },
  {
    icon: FileJson,
    label: "Debug",
    title: "JSON、错误日志、API response 很快混在一起",
    before: "靠肉眼扫剪贴板历史，类型不清楚。",
    after: "自动识别类型，卡片头部一眼区分 JSON、Code、URL、CMD。",
  },
  {
    icon: Shield,
    label: "Secrets",
    title: "复制 token 和验证码时，不想留下明文历史",
    before: "担心剪贴板工具默默保存敏感内容。",
    after: "敏感过滤默认开启，命中规则后过滤或脱敏展示。",
  },
];

export default function UseCases() {
  return (
    <section className="border-b border-[#d9dde2] bg-white py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="mb-12 max-w-3xl">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#0a84ff]">
            Product translation
          </p>
          <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.03em] text-[#141922] sm:text-5xl">
            Demo 讲功能，官网讲场景。
          </h2>
          <p className="mt-5 text-lg leading-8 text-[#5f6b7a]">
            所以 Bufferly 不从“自动监听剪贴板”开始讲，而是从开发者每天真的会遇到的复制断点开始讲。
          </p>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          {scenarios.map((scenario) => (
            <article key={scenario.title} className="rounded-[24px] border border-[#d7dde5] bg-[#f8f9fa] p-5">
              <div className="mb-5 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-11 w-11 items-center justify-center rounded-xl border border-[#d7dde5] bg-white text-[#11161d]">
                    <scenario.icon size={21} />
                  </div>
                  <span className="text-xs font-semibold uppercase tracking-[0.16em] text-[#6a7481]">
                    {scenario.label}
                  </span>
                </div>
              </div>
              <h3 className="text-xl font-semibold tracking-[-0.02em] text-[#18202a]">{scenario.title}</h3>
              <div className="mt-5 grid gap-3 sm:grid-cols-2">
                <div className="rounded-2xl border border-[#dde3ea] bg-white p-4">
                  <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[#8a5360]">Before</p>
                  <p className="mt-2 text-sm leading-6 text-[#667382]">{scenario.before}</p>
                </div>
                <div className="rounded-2xl border border-[#cfe0d7] bg-[#f7fbf8] p-4">
                  <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[#1f7a4d]">After</p>
                  <p className="mt-2 text-sm leading-6 text-[#405044]">{scenario.after}</p>
                </div>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
