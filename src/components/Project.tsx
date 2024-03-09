import Link from "next/link";

const languagesIcons = {
	c: "",
	"c++": "",
	typescript: "󰛦",
	python: "",
	lua: "",
	php: "",
	meowian: "󰄛",
};

export default function Project(props: IProject) {
	return (
		<div className="flex w-80 flex-col gap-4 rounded-lg border border-primary border-opacity-50 p-4">
			<div className="flex items-center justify-between">
				<div className="flex flex-col flex-wrap">
					<h3 className="text-xl uppercase">
						{props.name.replaceAll(/[-_]/g, " ")}
					</h3>
					<div className="flex items-center gap-2 text-sm text-primary text-opacity-75">
						<span className="select-none">
							{
								languagesIcons[
									props.language.toLowerCase() as keyof typeof languagesIcons
								]
							}
						</span>
						<span>{props.language}</span>
					</div>
				</div>
			</div>
			<p>{props.description}</p>
			<div className="flex flex-wrap gap-2 text-primary text-opacity-75">
				{props.topics.map((topic: string) => (
					<span
						key={topic}
						className="rounded-md border border-primary border-opacity-50 p-1 text-xs"
					>
						{topic}
					</span>
				))}
			</div>
			<div className="mt-auto flex gap-2 justify-self-end uppercase">
				{props.homepage && (
					<Link
						href={props.homepage}
						className="w-full rounded-md border border-primary border-opacity-50 p-[0.1rem] text-center duration-200 hover:border-opacity-75"
						target="_blank"
					>
						Site
					</Link>
				)}
				<Link
					href={props.html_url}
					className="w-full rounded-md border border-primary border-opacity-50 p-[0.1rem] text-center duration-200 hover:border-opacity-75"
					target="_blank"
				>
					Repo
				</Link>
			</div>
		</div>
	);
}
