import { Github, MessageCircle, Tag } from "lucide-react";

const productLinks = [
  { label: "信任系统", href: "#trust" },
  { label: "工作流", href: "#workflow" },
  { label: "隐私承诺", href: "#privacy" },
  { label: "下载", href: "#download" },
];

const repoLinks = [
  { label: "GitHub", href: "https://github.com/Innate-Labs/bufferly", icon: Github },
  { label: "Issues", href: "https://github.com/Innate-Labs/bufferly/issues", icon: MessageCircle },
  { label: "Releases", href: "https://github.com/Innate-Labs/bufferly/releases", icon: Tag },
];

const Footer = () => {
  return (
    <footer className="border-t border-zinc-200 bg-[#f7f8f8] py-10 text-zinc-600">
      <div className="container mx-auto px-5 sm:px-6 lg:px-8">
        <div className="grid gap-8 md:grid-cols-[1.5fr_1fr_1fr]">
          <div className="max-w-md">
            <div className="mb-4 flex items-center gap-3">
              <div className="grid h-9 w-9 place-items-center rounded-[10px] border border-zinc-200 bg-white text-sm font-semibold text-zinc-950 shadow-sm">
                B
              </div>
              <span className="text-base font-semibold text-zinc-950">Bufferly</span>
            </div>
            <p className="text-sm leading-6">
              本地优先的 macOS 剪贴板工作台，面向开发者、AI 重度用户和每天需要反复复制上下文的人。
            </p>
          </div>

          <div>
            <h4 className="mb-3 text-sm font-semibold text-zinc-950">Product</h4>
            <ul className="space-y-2">
              {productLinks.map((link) => (
                <li key={link.label}>
                  <a className="text-sm transition hover:text-zinc-950" href={link.href}>
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="mb-3 text-sm font-semibold text-zinc-950">Open Source</h4>
            <ul className="space-y-2">
              {repoLinks.map((link) => {
                const Icon = link.icon;

                return (
                  <li key={link.label}>
                    <a
                      className="inline-flex items-center gap-2 text-sm transition hover:text-zinc-950"
                      href={link.href}
                      target="_blank"
                      rel="noreferrer"
                    >
                      <Icon className="h-4 w-4" />
                      {link.label}
                    </a>
                  </li>
                );
              })}
            </ul>
          </div>
        </div>

        <div className="mt-10 flex flex-col gap-3 border-t border-zinc-200 pt-5 text-xs text-zinc-500 sm:flex-row sm:items-center sm:justify-between">
          <p>2026 Innate Labs. Built for local-first workflows.</p>
          <p>Not a cloud clipboard. Not another command history.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
