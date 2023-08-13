type ProjectProps = {
	name: string;
	language: string;
	homepage: string;
	html_url: string;
	description: string;
	topics: string[];
};

export default function Project(props: ProjectProps) {
	return (
		<div className="border-primary flex w-80 flex-col gap-2 rounded-lg border border-opacity-50 p-4">
			<div className="flex items-center justify-between">
				<div className="flex flex-col flex-wrap">
					<h3 className="text-xl uppercase">
						{props.name.replaceAll("-", " ")}
					</h3>
					<span className="text-primary text-sm text-opacity-75">
						{props.language}
					</span>
				</div>
			</div>
			<p>{props.description}</p>
			<div className="text-primary flex flex-wrap gap-2 text-opacity-75">
				{props.topics.map((topic: string) => (
					<span
						key={topic}
						className="border-primary rounded-md border border-opacity-50 p-1 text-xs"
					>
						{topic}
					</span>
				))}
			</div>
			<div className="mt-auto flex gap-2 justify-self-end uppercase">
				{props.homepage && (
					<a
						href={props.homepage}
						className="border-primary w-full rounded-md border border-opacity-50 text-center duration-200 hover:opacity-75"
					>
						Site
					</a>
				)}
				<a
					href={props.html_url}
					className="border-primary w-full rounded-md border border-opacity-50 text-center duration-200 hover:opacity-75"
				>
					Repo
				</a>
			</div>
		</div>
	);
}
