import { Database, EyeOff, LockKeyhole, WifiOff } from "lucide-react";

const privacyItems = [
  {
    icon: Database,
    title: "历史记录只在本机",
    description: "剪贴板历史默认保存在本地 SQLite，不需要账号，也不依赖云同步。",
  },
  {
    icon: LockKeyhole,
    title: "敏感内容先过滤",
    description: "token、password、验证码、.env value 命中规则后不保存明文。",
  },
  {
    icon: WifiOff,
    title: "联网行为默认关闭",
    description: "链接预览默认关闭；只有你在设置里开启后，才会请求 URL 预览信息。",
  },
  {
    icon: EyeOff,
    title: "排除 App 可控",
    description: "密码管理器、Keychain 等来源可以排除，避免把不该留的内容放进历史。",
  },
];

export default function Privacy() {
  return (
    <section id="privacy" className="border-b border-[#d9dde2] bg-[#f7f8f8] py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-5 sm:px-8">
        <div className="grid gap-12 lg:grid-cols-[0.95fr_1.05fr] lg:items-center">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#0a84ff]">
              Proof
            </p>
            <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.03em] text-[#141922] sm:text-5xl">
              专业感不是高级 UI，是证据完整。
            </h2>
            <p className="mt-5 text-lg leading-8 text-[#5f6b7a]">
              对剪贴板工具来说，最重要的证据不是口号，而是它如何处理你的本地数据、敏感文本和联网行为。
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            {privacyItems.map((item) => (
              <article key={item.title} className="rounded-2xl border border-[#d7dde5] bg-white p-5">
                <div className="mb-5 flex h-11 w-11 items-center justify-center rounded-xl bg-[#11161d] text-white">
                  <item.icon size={20} />
                </div>
                <h3 className="text-lg font-semibold text-[#18202a]">{item.title}</h3>
                <p className="mt-3 text-sm leading-6 text-[#667382]">{item.description}</p>
              </article>
            ))}
          </div>
        </div>

        <div className="mt-12 rounded-[28px] border border-[#d0d7df] bg-white p-5 sm:p-6">
          <div className="grid gap-6 lg:grid-cols-[0.7fr_1.3fr] lg:items-center">
            <div>
              <p className="text-sm font-semibold text-[#18202a]">Local-first by default</p>
              <p className="mt-2 text-sm leading-6 text-[#667382]">
                这也是为什么 Bufferly 暂不做账号系统、云同步和团队共享。产品边界本身就是隐私承诺的一部分。
              </p>
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <div className="rounded-2xl bg-[#f7f8f8] p-4">
                <p className="text-2xl font-semibold text-[#18202a]">0</p>
                <p className="mt-1 text-xs text-[#667382]">cloud account required</p>
              </div>
              <div className="rounded-2xl bg-[#f7f8f8] p-4">
                <p className="text-2xl font-semibold text-[#18202a]">500</p>
                <p className="mt-1 text-xs text-[#667382]">recent clips target</p>
              </div>
              <div className="rounded-2xl bg-[#f7f8f8] p-4">
                <p className="text-2xl font-semibold text-[#18202a]">opt-in</p>
                <p className="mt-1 text-xs text-[#667382]">network previews</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
