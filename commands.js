import data from "./data.js";

const commands = {
	about: {
		description: "display info about me",
		arguments: null,
		hidden: false,
		action: (_, output) => {
			output.innerHTML += `<div>${data.about}</div>`;
		},
	},

	contact: {
		description: "display contact info",
		arguments: null,
		hidden: false,
		action: (_, output) => {
			output.innerHTML += `<div><a href="mailto:${data.contact.email}">󰇮 ${data.contact.email}</a></div>`;
			output.innerHTML += `<div><a href="${data.contact.github}"> ${data.contact.github}</a></div>`;
		},
	},

	projects: {
		description: "display projects or details of a project",
		arguments: "[project]",
		hidden: false,
		action: (argv, output) => {
			if (argv.length > 1) {
				project = data.projects.find((p) => p.name === argv[1]);
				if (project === undefined) {
					output.innerHTML += `<div>No project found with name '${argv[1]}'</div>`;
					return;
				}

				output.innerHTML += `<div><span style="color:#808080">Neme:</span> ${project.name}</div>`;
				output.innerHTML += `<div><span style="color:#808080">Description:</span> ${project.description}</div>`;
				output.innerHTML += `<div><span style="color:#808080">Repository:</span> <a href="${project.repository}">${project.repository}</a></div>`;
				output.innerHTML += `<div><span style="color:#808080">Language:</span> ${project.language}</div>`;
				return;
			}

			let maxNameLen =
				data.projects
					.map((proj) => proj.name.length)
					.sort()
					.reverse()[0] + 4;

			for (const project of data.projects) {
				const name = `<a href="${project.repository}" style="color:#808080">${project.name}</a>`;
				const padding = " ".repeat(maxNameLen - project.name.length);
				const description = project.description;
				output.innerHTML += `<div>${name + padding + description}</div>`;
			}
		},
	},

	echo: {
		description: "display a line of text",
		arguments: "[args]...",
		hidden: false,
		action: (argv, output) => {
			output.innerHTML += `<div>${argv.slice(1).join(" ")}</div>`;
		},
	},

	clear: {
		description: "clear the terminal screen",
		arguments: null,
		hidden: false,
		action: (_, output) => {
			output.innerHTML = "";
		},
	},

	cat: {
		description: "meow",
		arguments: null,
		hidden: false,
		action: async (_, output) => {
			const res = await fetch("https://api.thecatapi.com/v1/images/search");
			const data = await res.json();
			output.innerHTML += `<div><img src="${data[0].url}" style="width:50%" alt="Cat!"></div>`;
			setTimeout(() => {
				window.scrollTo(0, document.body.scrollHeight);
			}, 200);
		},
	},

	pspsps: {
		description: null,
		arguments: null,
		hidden: true,
		action: (_, output) => {
			output.innerHTML += "meow";
		},
	},

	help: {
		description: "display this help message",
		arguments: null,
		hidden: false,
		action: (_, output) => {
			let maxUsageLen =
				Object.keys(commands)
					.map((cmd) => cmd.length + (commands[cmd].arguments?.length ?? 0))
					.sort((a, b) => a - b)
					.reverse()[0] + 4;

			for (const cmd in commands) {
				if (commands[cmd].hidden) {
					continue;
				}

				const usage = `<span style="color:#808080">${cmd + " " + (commands[cmd].arguments ?? "")}</span>`;
				const padding = `<span>${" ".repeat(maxUsageLen - cmd.length - (commands[cmd].arguments?.length ?? 0))}</span>`;
				const description = commands[cmd].description;
				output.innerHTML += `<div>${usage + padding + description}</div>`;
			}
		},
	},
};

export default commands;
