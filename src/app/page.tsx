import Footer from "@/components/Footer";
import Header from "@/components/Header";
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
				<div className="bg-secondary relative w-full">
					<div className="m-auto flex max-w-6xl flex-col px-8">
						<Projects />
						<About />
						<Contact />
					</div>
				</div>
			</main>
			<Footer />
		</>
	);
}
