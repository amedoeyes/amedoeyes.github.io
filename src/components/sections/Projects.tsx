import Section from "@/components/Section";
import ProjectsList from "./utils/ProjectsList";

async function getProject(repo: string) {
	const res = await fetch(`https://api.github.com/repos/${repo}`);

	if (!res.ok) {
		throw new Error("Failed to fetch data");
	}

	return res.json();
}

export default async function Projects() {
	const projectsList = [
		"amedoeyes/sheets",
		"amedoeyes/resume",
		"amedoeyes/retina",
		"amedoeyes/users-api-laravel",
		"amedoeyes/oshop",
		"amedoeyes/numverify",
		"amedoeyes/spreadsheet",
		"amedoeyes/fish-farming-in-lake-burullus",
		"amedoeyes/eyes.nvim",
	];

	const projects = await Promise.all(projectsList.map(getProject));

	return (
		<Section id="projects" title="Projects">
			<ProjectsList projects={projects} />
		</Section>
	);
}
