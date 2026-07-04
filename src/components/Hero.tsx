import { Download, Github, Pin, Search } from "lucide-react";

type ClipKind = "json" | "command" | "text" | "url" | "code" | "email" | "secret";

type ClipCard = {
  kind: ClipKind;
  label: string;
  title: string;
  content: string;
  source: string;
  sourceIcon: "ghostty" | "dia" | "codex" | "terminal" | "safari" | "xcode" | "mail";
  time: string;
  icon: string;
  accent: string;
  pinned?: boolean;
  sensitive?: boolean;
};

const clipCards: ClipCard[] = [
  {
    kind: "text",
    label: "文本",
    title: "Seed script note",
    content: "Dev/emotest-github/supabase-seed-fake-data.sql:11 里硬编码了一个实时",
    source: "Ghostty",
    sourceIcon: "ghostty",
    time: "10 分钟前",
    icon: "align-left",
    accent: "#0A8DFF",
  },
  {
    kind: "text",
    label: "文本",
    title: "Seed script line",
    content: "Dev/emotest-github/supabase-seed-fake-data.sql:11",
    source: "Ghostty",
    sourceIcon: "ghostty",
    time: "11 分钟前",
    icon: "align-left",
    accent: "#0A8DFF",
  },
  {
    kind: "url",
    label: "URL",
    title: "JCodesMore/ai-website-cloner-template: Clone any website with one command",
    content: "https://github.com/JCodesMore/ai-website-cloner-template.git",
    source: "Dia",
    sourceIcon: "dia",
    time: "12 分钟前",
    icon: "link",
    accent: "#34C759",
  },
  {
    kind: "url",
    label: "URL",
    title: "Bufferly - 本地优先的 macOS 剪贴板工作台",
    content: "http://localhost:5175/",
    source: "Codex",
    sourceIcon: "codex",
    time: "13 分钟前",
    icon: "link",
    accent: "#34C759",
  },
  {
    kind: "url",
    label: "URL",
    title: "github.com",
    content: "https://github.com/realruian/emotest.git",
    source: "Dia",
    sourceIcon: "dia",
    time: "14 分钟前",
    icon: "link",
    accent: "#34C759",
  },
  {
    kind: "text",
    label: "文本",
    title: "Repo visibility",
    content: "确认公开 realruian/emotest",
    source: "Ghostty",
    sourceIcon: "ghostty",
    time: "14 分钟前",
    icon: "align-left",
    accent: "#0A8DFF",
  },
];

function TablerIcon({ name, className, color }: { name: string; className?: string; color?: string }) {
  return (
    <span
      aria-hidden="true"
      className={className}
      style={{
        WebkitMask: `url('/bufferly-icons/${name}.svg') center / contain no-repeat`,
        mask: `url('/bufferly-icons/${name}.svg') center / contain no-repeat`,
        backgroundColor: color,
      }}
    />
  );
}

function jsonPreview(text: string) {
  try {
    return JSON.stringify(JSON.parse(text), null, 2);
  } catch {
    return text;
  }
}

function urlParts(value: string) {
  const withProtocol = value.startsWith("http") ? value : `https://${value}`;
  const url = new URL(withProtocol);
  return {
    host: url.host.replace(/^www\./, ""),
    path: `${url.pathname || "/"}${url.search}${url.hash}`,
  };
}

function SourceIcon({ source }: { source: ClipCard["sourceIcon"] }) {
  const iconMap: Record<ClipCard["sourceIcon"], { icon: string; background: string; color: string }> = {
    codex: { icon: "code", background: "#eef0ff", color: "#5557e9" },
    dia: { icon: "link", background: "#f1f4ff", color: "#4d75ff" },
    ghostty: { icon: "terminal-2", background: "#0c1424", color: "#74a7ff" },
    mail: { icon: "mail", background: "#fff0f5", color: "#ff2d55" },
    safari: { icon: "link", background: "#eef6ff", color: "#007aff" },
    terminal: { icon: "terminal-2", background: "#101820", color: "#93c5fd" },
    xcode: { icon: "code", background: "#edf0ff", color: "#5856d6" },
  };
  const item = iconMap[source];

  return (
    <span className="grid shrink-0 place-items-center overflow-hidden" style={{ width: 14, height: 14, borderRadius: 4, backgroundColor: item.background }}>
      <TablerIcon name={item.icon} className="block h-2.5 w-2.5" color={item.color} />
    </span>
  );
}

function ClipCardView({ clip }: { clip: ClipCard }) {
  return (
    <article
      className="flex shrink-0 flex-col overflow-hidden text-left"
      style={{
        width: 208,
        height: 272,
        borderRadius: 14,
        color: "#1f2937",
        backgroundColor: "#fbfbfc",
        boxShadow: "inset 0 0 0 1px rgba(0,0,0,0.08)",
      }}
    >
      <div
        className="flex items-start gap-2 text-white"
        style={{ height: 52, padding: "10px 14px", backgroundColor: clip.accent }}
      >
        <div className="min-w-0">
          <div className="font-semibold leading-5" style={{ fontSize: 15 }}>
            {clip.label}
          </div>
          <div className="mt-0.5 leading-3 text-white/80" style={{ fontSize: 11 }}>
            {clip.time}
          </div>
        </div>
        <div className="ml-auto grid h-6 w-6 place-items-center rounded-full bg-white/20">
          <TablerIcon name={clip.icon} className="block h-3.5 w-3.5" color="#ffffff" />
        </div>
      </div>

      <div className="flex flex-1 flex-col" style={{ padding: 14 }}>
        <div className="min-h-0 flex-1">{cardBody(clip)}</div>

        <div className="mt-2 flex items-center leading-4" style={{ gap: 5, fontSize: 11, color: "#6f7b8c" }}>
          <SourceIcon source={clip.sourceIcon} />
          <span className="truncate">{clip.source}</span>
          <span className="min-w-1 flex-1" />
          {clip.pinned && <Pin className="h-3 w-3" fill="#007AFF" color="#007AFF" strokeWidth={2.2} />}
        </div>
      </div>
    </article>
  );
}

function cardBody(clip: ClipCard) {
  if (clip.sensitive) {
    return (
      <div className="flex h-full flex-col items-start justify-start gap-2">
        <TablerIcon name="lock" className="block h-5 w-5" color="#ff9500" />
        <p className="leading-5" style={{ fontSize: 15, color: "#6f7b8c" }}>
          敏感内容已隐藏
        </p>
      </div>
    );
  }

  if (clip.kind === "command") {
    return (
      <div
        className="border"
        style={{
          borderRadius: 9,
          borderColor: "rgba(0,0,0,0.08)",
          backgroundColor: "rgba(0,0,0,0.055)",
          padding: 10,
        }}
      >
        <div className="mb-2 flex gap-1.5">
          <span className="h-1.5 w-1.5 rounded-full bg-green-500/75" />
          <span className="h-1.5 w-1.5 rounded-full bg-yellow-400/75" />
          <span className="h-1.5 w-1.5 rounded-full bg-red-500/75" />
        </div>
        <pre
          className="overflow-hidden whitespace-pre-wrap break-words font-mono"
          style={{ fontSize: 12, lineHeight: "17px", color: "#1f2937" }}
        >{`$ ${clip.content}`}</pre>
      </div>
    );
  }

  if (clip.kind === "json") {
    return (
      <div
        className="border"
        style={{
          borderRadius: 9,
          padding: 10,
          backgroundColor: `${clip.accent}12`,
          borderColor: `${clip.accent}24`,
        }}
      >
        <div className="flex items-center gap-2" style={{ marginBottom: 7 }}>
          <span className="font-semibold leading-4" style={{ color: clip.accent, fontSize: 11 }}>
            2 个键
          </span>
          <TablerIcon name="braces" className="ml-auto block h-3 w-3" color="#AF52DE" />
        </div>
        <pre
          className="line-clamp-8 overflow-hidden whitespace-pre-wrap break-words font-mono"
          style={{ fontSize: 11, lineHeight: "15px", color: "#1f2937" }}
        >
          {jsonPreview(clip.content)}
        </pre>
      </div>
    );
  }

  if (clip.kind === "url") {
    const parts = urlParts(clip.content);
    return (
      <div className="space-y-2">
        <div className="flex items-start" style={{ gap: 7 }}>
          <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full" style={{ color: clip.accent }}>
            <TablerIcon name="link" className="block h-4 w-4" color="currentColor" />
          </span>
          <p className="line-clamp-3 font-semibold leading-5" style={{ fontSize: 15, color: "#2c3138" }}>
            {clip.title || parts.host}
          </p>
        </div>
        <p className="line-clamp-3 leading-4" style={{ fontSize: 12, color: "#6f7b8c" }}>
          {parts.path === "/" ? "/" : parts.path}
        </p>
        <p className="line-clamp-2 break-all leading-4" style={{ fontSize: 11, color: "#9aa3b2" }}>
          {clip.content}
        </p>
      </div>
    );
  }

  if (clip.kind === "code") {
    return (
      <div className="flex items-start" style={{ gap: 9 }}>
        <span className="shrink-0 rounded-sm" style={{ width: 3, height: 136, backgroundColor: `${clip.accent}47` }} />
        <pre
          className="line-clamp-8 overflow-hidden whitespace-pre-wrap break-words font-mono"
          style={{ fontSize: 12, lineHeight: "17px", color: "#1f2937" }}
        >
          {clip.content}
        </pre>
      </div>
    );
  }

  if (clip.kind === "email") {
    return (
      <div className="space-y-2">
        <div className="flex items-start gap-2">
          <TablerIcon name="mail" className="block h-5 w-5 shrink-0" color="#FF2D55" />
          <p className="line-clamp-2 font-medium leading-5" style={{ fontSize: 15, color: "#1f2937" }}>
            {clip.title}
          </p>
        </div>
        <p className="line-clamp-5 leading-4" style={{ fontSize: 12, color: "#6f7b8c" }}>
          {clip.content}
        </p>
      </div>
    );
  }

  return (
    <p className="line-clamp-9 font-semibold" style={{ fontSize: 15, lineHeight: "23px", color: "#2c3138" }}>
      {clip.content}
    </p>
  );
}

function QuickPanelMock() {
  return (
    <div
      className="overflow-hidden backdrop-blur-2xl"
      style={{
        width: 1280,
        height: 370,
        borderRadius: 34,
        color: "#1f2937",
        border: "1px solid rgba(0,0,0,0.08)",
        backgroundColor: "rgba(238,238,238,0.58)",
        boxShadow: "0 36px 110px rgba(63,71,83,0.24)",
      }}
    >
      <div className="flex items-center gap-3 px-5 pt-5">
        <div
          className="flex items-center gap-2 rounded-full border border-white/40 bg-white/30 leading-8 shadow-[inset_0_1px_1px_rgba(255,255,255,0.85)] backdrop-blur-xl"
          style={{ width: 320, height: 32, padding: "0 14px", fontSize: 15 }}
        >
          <Search className="h-4 w-4 shrink-0" color="#6f7b8c" />
          <span style={{ color: "#6f7b8c" }}>搜索剪贴板</span>
        </div>

        <div className="min-w-2 flex-1" />

        <div
          className="flex items-center rounded-full border border-white/40 bg-white/20 shadow-[inset_0_1px_1px_rgba(255,255,255,0.78)] backdrop-blur-xl"
          style={{ gap: 3, padding: 3 }}
        >
          <span className="rounded-full bg-white/95 px-3 font-medium leading-7 shadow-[0_1px_3px_rgba(0,0,0,0.10)]" style={{ fontSize: 15, color: "#1f2937" }}>
            剪贴板
          </span>
          <span className="px-3 font-medium leading-7" style={{ fontSize: 15, color: "#6f7b8c" }}>
            已固定
          </span>
        </div>
      </div>

      <div className="overflow-hidden px-5 py-5">
        <div className="flex gap-4" style={{ transform: "translateX(-224px)" }}>
          {clipCards.map((clip) => (
            <ClipCardView key={`${clip.label}-${clip.title}`} clip={clip} />
          ))}
        </div>
      </div>
    </div>
  );
}

export default function Hero() {
  return (
    <section className="relative min-h-[1040px] overflow-hidden bg-[#158cff] text-white sm:min-h-[1100px] lg:min-h-[1120px]">
      <div
        aria-hidden="true"
        className="absolute inset-0 bg-[linear-gradient(180deg,#2333c4_0%,#087cff_35%,#52baff_62%,#bdeeff_82%,#f7f8f8_100%)]"
      />
      <div
        aria-hidden="true"
        className="absolute inset-x-0 bottom-0 h-[68%] bg-cover bg-center sm:h-[58%] lg:h-[52%]"
        style={{
          backgroundImage:
            "linear-gradient(180deg, rgba(82,186,255,0) 0%, rgba(82,186,255,0.05) 18%, rgba(247,248,248,0.36) 72%, rgba(247,248,248,0.98) 100%), url('/bufferly-meadow.jpg')",
          WebkitMaskImage: "linear-gradient(180deg, transparent 0%, black 22%, black 100%)",
          maskImage: "linear-gradient(180deg, transparent 0%, black 22%, black 100%)",
        }}
      />
      <div
        aria-hidden="true"
        className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-b from-transparent to-[#f7f8f8]"
      />

      <div
        className="relative z-10 mx-auto flex max-w-5xl flex-col items-center px-5 text-center sm:px-8"
        style={{ paddingTop: 104 }}
      >
        <h1 className="mt-6 text-6xl font-semibold leading-none text-white sm:text-7xl lg:text-8xl">
          Copy once.
          <span className="mt-1 block font-serif italic font-normal">Recall anytime.</span>
        </h1>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-white/90 sm:text-xl sm:leading-9">
          Bufferly 把命令、Prompt、JSON、链接留在本机；token、密码、验证码进入历史前先被拦下。
        </p>

        <div className="mt-6 flex w-full flex-col justify-center gap-3 sm:w-auto sm:flex-row">
          <a
            href="#download"
            className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-6 py-4 text-sm font-semibold text-[#06356f] shadow-[0_18px_55px_rgba(6,53,111,0.22)] transition hover:-translate-y-0.5 hover:bg-[#f1f7ff] focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-[#168cff]"
          >
            <Download size={18} />
            Download for macOS
          </a>
          <a
            href="https://github.com/Innate-Labs/bufferly"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 rounded-2xl border border-white/40 bg-white/10 px-6 py-4 text-sm font-semibold text-white backdrop-blur-md transition hover:-translate-y-0.5 hover:bg-white/20 focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-[#168cff]"
          >
            <Github size={18} />
            View source
          </a>
        </div>

      </div>

      <div className="relative z-10 mt-6 flex w-full justify-center sm:mt-8">
        <div className="shrink-0" style={{ width: 1280 }}>
          <QuickPanelMock />
        </div>
      </div>
    </section>
  );
}
