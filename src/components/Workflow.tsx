import { ArrowRight, ClipboardCheck, Keyboard, MousePointer2, Search } from "lucide-react";

const workflowSteps = [
  {
    icon: Keyboard,
    key: "Option Space",
    title: "呼出工作台",
    description: "面板贴近当前工作流出现，默认聚焦搜索，不需要从菜单里找。",
  },
  {
    icon: Search,
    key: "type",
    title: "搜索上下文",
    description: "按关键词、类型、来源快速过滤最近复制过的内容。",
  },
  {
    icon: MousePointer2,
    key: "← / →",
    title: "扫读卡片",
    description: "用横向卡片墙浏览命令、代码、URL、JSON 和 prompt。",
  },
  {
    icon: ClipboardCheck,
    key: "Return",
    title: "写回剪贴板",
    description: "回车复制选中内容，并可选粘贴回上一个前台应用。",
  },
];

const shortcuts = [
  ["Cmd P", "固定或取消固定"],
  ["Esc", "关闭面板"],
  ["Return", "复制或粘贴"],
  ["Cmd Delete", "删除历史"],
];

export default function Workflow() {
  return (
    <section id="workflow" className="border-b border-[#d9dde2] bg-[#f7f8f8] py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="mb-12 flex flex-col justify-between gap-6 lg:flex-row lg:items-end">
          <div className="max-w-2xl">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#0a84ff]">
              Workflow
            </p>
            <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.03em] text-[#141922] sm:text-5xl">
              从复制到粘贴，尽量不离开键盘。
            </h2>
          </div>
          <p className="max-w-xl text-base leading-7 text-[#647181]">
            Bufferly 的核心不是“保存很多东西”，而是让你在 IDE、终端、浏览器和 AI 工具之间少一次打断。
          </p>
        </div>

        <div className="grid gap-4 lg:grid-cols-4">
          {workflowSteps.map((step, index) => (
            <article key={step.title} className="relative rounded-2xl border border-[#d7dde5] bg-white p-5">
              {index < workflowSteps.length - 1 && (
                <ArrowRight className="absolute -right-3 top-8 z-10 hidden h-6 w-6 rounded-full border border-[#d7dde5] bg-[#f7f8f8] p-1 text-[#8a96a3] lg:block" />
              )}
              <div className="mb-7 flex items-center justify-between">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#11161d] text-white">
                  <step.icon size={20} />
                </div>
                <kbd className="rounded-lg border border-[#cfd6de] bg-[#f7f8f8] px-2.5 py-1 text-xs font-semibold text-[#39434f]">
                  {step.key}
                </kbd>
              </div>
              <h3 className="text-lg font-semibold text-[#18202a]">{step.title}</h3>
              <p className="mt-3 text-sm leading-6 text-[#667382]">{step.description}</p>
            </article>
          ))}
        </div>

        <div className="mt-8 grid gap-4 rounded-[28px] border border-[#d7dde5] bg-white p-5 lg:grid-cols-[0.8fr_1.2fr] lg:p-6">
          <div>
            <h3 className="text-xl font-semibold tracking-[-0.02em] text-[#18202a]">
              快捷键是产品的一部分
            </h3>
            <p className="mt-3 text-sm leading-6 text-[#667382]">
              这不是一个重型素材库。它应该像 Spotlight 或 Raycast 一样出现、完成任务、消失。
            </p>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {shortcuts.map(([key, label]) => (
              <div key={key} className="rounded-2xl bg-[#f7f8f8] p-4">
                <kbd className="text-sm font-semibold text-[#18202a]">{key}</kbd>
                <p className="mt-2 text-xs text-[#667382]">{label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
