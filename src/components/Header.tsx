import { useEffect, useState } from "react";
import { Download, Github, Menu, X } from "lucide-react";

const navLinks = [
  { label: "信任系统", href: "#trust" },
  { label: "工作流", href: "#workflow" },
  { label: "隐私", href: "#privacy" },
  { label: "下载", href: "#download" },
];

export default function Header() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const isSolid = isScrolled || isMobileMenuOpen;

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 16);
    handleScroll();
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition ${
        isSolid
          ? "border-b border-[#d9dde2] bg-white/90 shadow-[0_1px_0_rgba(255,255,255,0.85)] backdrop-blur-xl"
          : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4 sm:px-8">
        <a href="/" className="flex items-center gap-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0a84ff] focus:ring-offset-2">
          <span
            className={`flex h-9 w-9 items-center justify-center rounded-xl border text-sm font-semibold shadow-sm transition ${
              isSolid
                ? "border-[#cbd2da] bg-white text-[#11161d]"
                : "border-white/40 bg-white/20 text-white backdrop-blur-md"
            }`}
          >
            B
          </span>
          <div className="leading-tight">
            <span className={`block text-sm font-semibold ${isSolid ? "text-[#11161d]" : "text-white"}`}>
              Bufferly
            </span>
            <span className={`hidden text-xs sm:block ${isSolid ? "text-[#768291]" : "text-white/70"}`}>
              local clipboard workspace
            </span>
          </div>
        </a>

        <nav className="hidden items-center gap-7 md:flex">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className={`text-sm font-medium transition focus:outline-none focus:ring-2 focus:ring-[#0a84ff] focus:ring-offset-2 ${
                isSolid ? "text-[#52606f] hover:text-[#11161d]" : "text-white/75 hover:text-white"
              }`}
            >
              {link.label}
            </a>
          ))}
        </nav>

        <div className="hidden items-center gap-3 md:flex">
          <a
            href="https://github.com/Innate-Labs/bufferly"
            target="_blank"
            rel="noopener noreferrer"
            className={`inline-flex h-10 w-10 items-center justify-center rounded-xl border transition focus:outline-none focus:ring-2 focus:ring-[#0a84ff] focus:ring-offset-2 ${
              isSolid
                ? "border-[#cbd2da] bg-white text-[#39434f] hover:border-[#aeb7c2] hover:text-[#11161d]"
                : "border-white/30 bg-white/10 text-white backdrop-blur-md hover:bg-white/20"
            }`}
            aria-label="Open Bufferly on GitHub"
          >
            <Github size={18} />
          </a>
          <a
            href="#download"
            className={`inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-[#0a84ff] focus:ring-offset-2 ${
              isSolid
                ? "bg-[#11161d] text-white hover:bg-[#202832]"
                : "bg-white text-[#06356f] shadow-[0_10px_32px_rgba(6,53,111,0.18)] hover:bg-[#f1f7ff]"
            }`}
          >
            <Download size={17} />
            Download
          </a>
        </div>

        <button
          className={`inline-flex h-10 w-10 items-center justify-center rounded-xl border transition md:hidden ${
            isSolid
              ? "border-[#cbd2da] bg-white text-[#11161d]"
              : "border-white/30 bg-white/10 text-white backdrop-blur-md"
          }`}
          onClick={() => setIsMobileMenuOpen((open) => !open)}
          aria-label={isMobileMenuOpen ? "Close navigation" : "Open navigation"}
          aria-expanded={isMobileMenuOpen}
        >
          {isMobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {isMobileMenuOpen && (
        <nav className="border-t border-[#d9dde2] bg-[#f8f9fa] px-5 py-4 md:hidden">
          <div className="mx-auto flex max-w-7xl flex-col gap-1">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="rounded-xl px-3 py-3 text-sm font-medium text-[#52606f] hover:bg-white hover:text-[#11161d]"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {link.label}
              </a>
            ))}
            <a
              href="#download"
              className="mt-3 inline-flex items-center justify-center gap-2 rounded-xl bg-[#11161d] px-4 py-3 text-sm font-semibold text-white"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              <Download size={17} />
              Download
            </a>
          </div>
        </nav>
      )}
    </header>
  );
}
