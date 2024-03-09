"use client";

import Project from "@/components/Project";
import { useState } from "react";
import ProjectsFilter from "./ProjectsFilter";

export default function ProjectsList(props: { projects: IProject[] }) {
	const [projects, setProjects] = useState(props.projects);

	return (
		<>
			<div className="mb-4">
				<ProjectsFilter projects={projects} onChange={setProjects} />
			</div>
			<div className="flex flex-wrap justify-center gap-4">
				{projects.map((project) => (
					<Project key={project.name} {...project} />
				))}
			</div>
		</>
	);
}
