export default function Hero() {
	return (
		<section
			id="hero"
			className="flex h-screen items-center justify-center bg-[url('/bg.gif')] bg-cover bg-fixed bg-center bg-no-repeat text-center"
		>
			<div className="fixed m-4 flex flex-col p-4 uppercase">
				<h1 className="text-4xl font-bold sm:text-6xl">
					Ahmed AbouEley<span>&lt;O&gt;</span>un
				</h1>
				<h2 className="text-2xl font-medium sm:text-4xl">
					Software Engineer
				</h2>
			</div>
		</section>
	);
}
