"use client";

import { useRef, useState } from "react";

export default function ProjectsFilter(props: {
	projects: IProject[];
	onChange: (projects: IProject[]) => void;
}) {
	const [selectValue, setSelectValue] = useState("create");
	const [searchValue, setSearchValue] = useState("");
	const originalProjects = useRef([...props.projects]);

	const sortProjects = (value: string) => {
		return originalProjects.current.slice().sort((a, b) => {
			switch (value) {
				case "create":
					return (
						new Date(b.created_at).getTime() -
						new Date(a.created_at).getTime()
					);
				case "update":
					return (
						new Date(b.updated_at).getTime() -
						new Date(a.updated_at).getTime()
					);
				case "push":
					return (
						new Date(b.pushed_at).getTime() -
						new Date(a.pushed_at).getTime()
					);
				default:
					return 0;
			}
		});
	};

	const filterProjects = (value: string) => {
		return originalProjects.current.filter((project) => {
			const { name, description, language, topics } = project;
			if (name.toLowerCase().includes(value)) return true;
			if (description?.toLowerCase().includes(value)) return true;
			if (language?.toLowerCase().includes(value)) return true;
			if (topics?.some((topic) => topic.toLowerCase().includes(value)))
				return true;
		});
	};

	const handleSelectChange = (event: React.FormEvent<HTMLSelectElement>) => {
		const currentValue = event.currentTarget.value;
		const projects = sortProjects(currentValue);
		originalProjects.current = projects;
		props.onChange(projects);
		setSelectValue(currentValue);
	};

	const handleSearchChange = (event: React.FormEvent<HTMLInputElement>) => {
		const currentValue = event.currentTarget.value.toLowerCase();
		const projects = filterProjects(currentValue);
		props.onChange(projects);
		setSearchValue(event.currentTarget.value);
	};

	return (
		<>
			<div className="flex items-center justify-center gap-4">
				<div>
					<label htmlFor="sort" className="mr-2 select-none">
						Sort:
					</label>
					<select
						name="sort"
						id="sort"
						value={selectValue}
						onChange={handleSelectChange}
						className="cursor-pointer rounded-lg border border-primary border-opacity-50 bg-secondary p-1 text-primary duration-200 hover:border-opacity-75"
					>
						<option value="create">Create</option>
						<option value="update">Update</option>
						<option value="push">Push</option>
					</select>
				</div>
				<div>
					<label htmlFor="search" className="mr-2 select-none">
						Search:
					</label>
					<input
						name="search"
						id="search"
						type="text"
						value={searchValue}
						onChange={handleSearchChange}
						className="rounded-lg border border-primary border-opacity-50 bg-secondary p-1 text-primary duration-200 hover:border-opacity-75"
					/>
				</div>
			</div>
		</>
	);
}
