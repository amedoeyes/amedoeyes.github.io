import Section from "../Section";

export default function Contact() {
	return (
		<Section id="contact" title="Contact">
			<p className="text-center">Feel free to contact me</p>
			<div className="flex justify-center gap-8">
				<div className="flex flex-col">
					<a
						href="mailto:ahmed.m.aboueleyoun@gmail.com"
						className="underline duration-200 hover:opacity-75"
					>
						ahmed.m.aboueleyoun@gmail.com
					</a>
					<a
						href="phone:+20 100 240 3588"
						className="underline duration-200 hover:opacity-75"
					>
						+20 100 240 3588
					</a>
				</div>
				<div className="flex flex-col">
					<a
						href="https://github.com/amedoeyes"
						className="underline duration-200 hover:opacity-75"
					>
						GitHub
					</a>
					<a
						href="https://linkedin.com/in/ahmed-aboueleyuon"
						className="underline duration-200 hover:opacity-75"
					>
						LinkedIn
					</a>
				</div>
			</div>
		</Section>
	);
}
