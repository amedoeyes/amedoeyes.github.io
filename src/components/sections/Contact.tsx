import Section from "../Section";

export default function Contact() {
	return (
		<Section id="contact" title="Contact">
			<p className="mb-2 text-center">Feel free to contact me</p>
			<div className="flex flex-col justify-center gap-2 underline sm:flex-row sm:gap-8">
				<div className="flex flex-col">
					<a
						href="mailto:ahmed.m.aboueleyoun@gmail.com"
						className="duration-200 hover:opacity-75"
					>
						ahmed.m.aboueleyoun@gmail.com
					</a>
					<a
						href="phone:+20 100 240 3588"
						className="duration-200 hover:opacity-75"
					>
						+20 100 240 3588
					</a>
				</div>
				<div className="flex flex-col">
					<a
						href="https://github.com/amedoeyes"
						className="duration-200 hover:opacity-75"
					>
						GitHub
					</a>
					<a
						href="https://linkedin.com/in/ahmed-aboueleyuon"
						className="duration-200 hover:opacity-75"
					>
						LinkedIn
					</a>
				</div>
			</div>
		</Section>
	);
}
