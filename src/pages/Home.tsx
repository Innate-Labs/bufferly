import Header from "@/components/Header";
import Hero from "@/components/Hero";
import Features from "@/components/Features";
import Workflow from "@/components/Workflow";
import UseCases from "@/components/UseCases";
import Privacy from "@/components/Privacy";
import AIRoadmap from "@/components/AIRoadmap";
import DownloadSection from "@/components/Download";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <div className="min-h-screen bg-[#f7f8f8] text-zinc-950">
      <Header />
      <main>
        <Hero />
        <Features />
        <Workflow />
        <UseCases />
        <Privacy />
        <AIRoadmap />
        <DownloadSection />
      </main>
      <Footer />
    </div>
  );
}
