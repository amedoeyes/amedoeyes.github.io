import Footer from "@/components/Footer";
import Header from "@/components/Header";
import Separator from "@/components/Separator";
import About from "@/components/sections/About";
import Contact from "@/components/sections/Contact";
import Hero from "@/components/sections/Hero";
import Projects from "@/components/sections/Projects";

export default function Home() {
	return (
		<>
			<Header />
			<main>
				<Hero />
				<div className="relative w-full bg-secondary">
					<div className="flex max-w-6xl flex-col gap-10 p-10">
						<Projects />
						<Separator />
						<About />
						<Separator />
						<Contact />
					</div>
				</div>
			</main>
			<Footer />
		</>
	);
}
