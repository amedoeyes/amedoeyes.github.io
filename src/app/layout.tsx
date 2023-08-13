import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
	title: "Ahmed AbouEleyoun",
	description: "Ahmed AbouEleyoun's portfolio",
};

export default function RootLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	return (
		<html lang="en" className="scroll-smooth">
			<body className="bg-secondary text-primary font-mono">
				{children}
			</body>
		</html>
	);
}
