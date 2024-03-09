"use client";

import { useEffect } from "react";

export default function Header() {
	useEffect(() => {
		const header = document.querySelector("header");
		const hero = document.querySelector("#hero");

		if (!header || !hero) return;

		const updateHeader = () => {
			if (window.scrollY >= hero.clientHeight - header.clientHeight) {
				header.classList.add("bg-secondary");
				header.classList.remove("border-b-transparent");
				header.classList.add("border-b-primary");
			} else {
				header.classList.remove("bg-secondary");
				header.classList.remove("border-b-primary");
				header.classList.add("border-b-transparent");
			}
		};
		updateHeader();

		window.addEventListener("scroll", updateHeader);
		return () => {
			window.removeEventListener("scroll", updateHeader);
		};
	}, []);

	return (
		<header className="fixed z-40 flex h-16 w-full items-center justify-between border-b border-b-transparent border-opacity-50 px-6 duration-200">
			<nav className="flex w-full items-center justify-between text-lg uppercase">
				<div>
					<a
						href="#"
						className="text-3xl font-bold duration-200 hover:opacity-75"
					>
						&lt;O&gt;
					</a>
				</div>
				<div className="flex gap-4">
					<a
						href="#projects"
						className="duration-200 hover:opacity-75"
					>
						Projects
					</a>
					<a href="#about" className="duration-200 hover:opacity-75">
						About
					</a>
					<a
						href="#contact"
						className="duration-200 hover:opacity-75"
					>
						Contact
					</a>
				</div>
			</nav>
		</header>
	);
}
