export default function Footer() {
	return (
		<footer className="flex h-16 items-center justify-center border-t border-t-primary border-opacity-50 bg-secondary">
			<p className="text-sm text-primary">
				&copy; {new Date().getFullYear()} Ahmed AbouEleyoun
			</p>
		</footer>
	);
}
