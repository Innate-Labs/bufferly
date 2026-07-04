import {
  Braces,
  ClipboardList,
  Command,
  FileCode2,
  KeyRound,
  Link2,
  Pin,
  Search,
  ShieldCheck,
} from "lucide-react";

const trustSystem = [
  {
    icon: Search,
    title: "复制过的内容能找回来",
    description: "模糊搜索最近历史，命令、错误日志、URL、prompt 不再被下一次复制覆盖掉。",
  },
  {
    icon: Pin,
    title: "常用片段固定在手边",
    description: "把高频 prompt、命令和模板 pin 住，呼出面板后直接搜索、选择、粘贴。",
  },
  {
    icon: ShieldCheck,
    title: "敏感内容默认先保护",
    description: "命中 token、password、验证码、.env value 时，默认过滤或脱敏展示。",
  },
];

const typeItems = [
  { icon: Command, label: "CMD", text: "Shell commands" },
  { icon: Braces, label: "JSON", text: "API payloads" },
  { icon: FileCode2, label: "Code", text: "Code snippets" },
  { icon: Link2, label: "URL", text: "Links and docs" },
  { icon: KeyRound, label: "Secret", text: "Blocked secrets" },
  { icon: ClipboardList, label: "Text", text: "Temporary notes" },
];

export default function Features() {
  return (
    <section id="trust" className="border-b border-[#d9dde2] bg-white py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="grid gap-12 lg:grid-cols-[0.78fr_1.22fr] lg:items-start">
          <div className="max-w-xl">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#0a84ff]">
              Trust system
            </p>
            <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.03em] text-[#141922] sm:text-5xl">
              官网不是装饰，产品也不只是功能。
            </h2>
            <p className="mt-5 text-lg leading-8 text-[#5f6b7a]">
              Bufferly 的信任来自三个很具体的承诺：本地保存、可快速找回、敏感内容默认被拦住。
              页面里的每一块信息都服务于这三个判断。
            </p>
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            {trustSystem.map((item) => (
              <article key={item.title} className="rounded-2xl border border-[#d7dde5] bg-[#f8f9fa] p-5">
                <div className="mb-5 flex h-11 w-11 items-center justify-center rounded-xl border border-[#d7dde5] bg-white text-[#11161d]">
                  <item.icon size={21} />
                </div>
                <h3 className="text-lg font-semibold tracking-[-0.01em] text-[#18202a]">{item.title}</h3>
                <p className="mt-3 text-sm leading-6 text-[#667382]">{item.description}</p>
              </article>
            ))}
          </div>
        </div>

        <div className="mt-14 rounded-[28px] border border-[#d7dde5] bg-[#f7f8f8] p-4 sm:p-6">
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-6">
            {typeItems.map((item) => (
              <div key={item.label} className="rounded-2xl border border-[#dbe0e7] bg-white p-4">
                <div className="flex items-center justify-between gap-3">
                  <item.icon className="h-5 w-5 text-[#566273]" />
                  <span className="rounded-full bg-[#eef2f6] px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-[#4b5563]">
                    {item.label}
                  </span>
                </div>
                <p className="mt-5 text-sm font-medium text-[#1d2630]">{item.text}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
