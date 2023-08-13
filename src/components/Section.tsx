type SectionProps = {
	id: string;
	title: string;
	className?: string;
	children: React.ReactNode;
};

export default function Section(props: SectionProps) {
	return (
		<section
			id={props.id}
			className={`scroll-m-20 ${props.className && props.className}`}
		>
			<h2 className="mb-8 text-center text-2xl font-medium uppercase sm:text-4xl ">
				{props.title}
			</h2>
			{props.children}
		</section>
	);
}
