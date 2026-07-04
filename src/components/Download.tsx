import { Apple, Download as DownloadIcon, Github, Terminal } from "lucide-react";

export default function DownloadSection() {
  return (
    <section id="download" className="bg-[#11161d] py-20 text-white sm:py-24">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="grid min-w-0 gap-10 lg:grid-cols-[0.88fr_1.12fr] lg:items-center">
          <div className="min-w-0">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#8ab8ff]">
              Download
            </p>
            <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.03em] sm:text-5xl">
              在你的 Mac 上试用 Bufferly。
            </h2>
            <p className="mt-5 max-w-xl text-lg leading-8 text-[#b8c1cc]">
              免费、开源、Swift 原生。MVP 仍在快速迭代，建议从 GitHub release 或源码构建开始。
            </p>

            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <a
                href="https://github.com/Innate-Labs/bufferly/releases/latest"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 rounded-xl bg-white px-5 py-3 text-sm font-semibold text-[#11161d] transition hover:-translate-y-0.5 hover:bg-[#eef2f6] focus:outline-none focus:ring-2 focus:ring-[#8ab8ff] focus:ring-offset-2 focus:ring-offset-[#11161d]"
              >
                <DownloadIcon size={18} />
                Download latest release
              </a>
              <a
                href="https://github.com/Innate-Labs/bufferly"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 rounded-xl border border-white/18 bg-white/6 px-5 py-3 text-sm font-semibold text-white transition hover:-translate-y-0.5 hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-[#8ab8ff] focus:ring-offset-2 focus:ring-offset-[#11161d]"
              >
                <Github size={18} />
                View repository
              </a>
            </div>
          </div>

          <div className="min-w-0 rounded-[28px] border border-white/12 bg-white/[0.04] p-5">
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="rounded-2xl bg-white/[0.06] p-5">
                <Apple className="h-6 w-6 text-[#d6dde6]" />
                <h3 className="mt-5 font-semibold">macOS native</h3>
                <p className="mt-2 text-sm leading-6 text-[#aeb8c5]">
                  SwiftUI + AppKit，不是 Electron 壳。
                </p>
              </div>
              <div className="rounded-2xl bg-white/[0.06] p-5">
                <Terminal className="h-6 w-6 text-[#d6dde6]" />
                <h3 className="mt-5 font-semibold">Build from source</h3>
                <p className="mt-2 text-sm leading-6 text-[#aeb8c5]">
                  脚本会构建、签名并生成本地 app。
                </p>
              </div>
              <div className="rounded-2xl bg-white/[0.06] p-5">
                <Github className="h-6 w-6 text-[#d6dde6]" />
                <h3 className="mt-5 font-semibold">Open source</h3>
                <p className="mt-2 text-sm leading-6 text-[#aeb8c5]">
                  MIT licensed，欢迎 fork 和贡献。
                </p>
              </div>
            </div>

            <div className="mt-4 overflow-hidden rounded-2xl border border-white/10 bg-[#070a0f]">
              <div className="border-b border-white/10 px-4 py-3 text-xs font-medium text-[#8b96a4]">
                build locally
              </div>
              <pre className="max-w-full overflow-x-auto p-4 text-sm leading-7 text-[#d6dde6]">
                <code className="block min-w-max">{`git clone https://github.com/Innate-Labs/bufferly.git
cd bufferly
bash scripts/build-app.sh`}</code>
              </pre>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
