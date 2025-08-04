import data from "./data.js";

const commands = {
	echo: {
		description: "display a line of text",
		arguments: "[args]...",
		action: (argv, output) => {
			output.innerHTML += `<div>${argv.slice(1).join(" ")}</div>`;
		},
	},
	clear: {
		description: "clear the terminal screen",
		arguments: "",
		action: (_, output) => {
			output.innerHTML = "";
		},
	},
	about: {
		description: "display info about me",
		arguments: "",
		action: (_, output) => {
			output.innerHTML += `<div>${data.about}</div>`;
		},
	},
	contact: {
		description: "display contact info",
		arguments: "",
		action: (_, output) => {
			output.innerHTML += `<div><a href="mailto:${data.contact.email}">󰇮 ${data.contact.email}</a></div>`;
			output.innerHTML += `<div><a href="${data.contact.github}"> ${data.contact.github}</a></div>`;
		},
	},
	projects: {
		description: "display projects or details of a project",
		arguments: "[project]",
		action: (argv, output) => {
			if (argv.length > 1) {
				project = data.projects.find((p) => p.name === argv[1]);
				if (project === undefined) {
					output.innerHTML += `<div>No project with name: ${argv[1]}</div>`;
					return;
				}
				output.innerHTML += `<div><span style="color:#808080">Neme:</span> ${project.name}</div>`;
				output.innerHTML += `<div><span style="color:#808080">Description:</span> ${project.description}</div>`;
				output.innerHTML += `<div><span style="color:#808080">Repository:</span> <a href="${project.repository}">${project.repository}</a></div>`;
				output.innerHTML += `<div><span style="color:#808080">Language:</span> ${project.language}</div>`;
				return;
			}
			let padding =
				data.projects
					.map((proj) => proj.name.length)
					.sort()
					.reverse()[0] + 4;
			for (const project of data.projects) {
				output.innerHTML += `<div>${`<a href="${project.repository}" style="color:#808080">${project.name}</a>` + " ".repeat(padding - project.name.length) + project.description}</div>`;
			}
		},
	},
	cat: {
		description: "meow",
		arguments: "",
		action: async (_, output) => {
			const res = await fetch("https://api.thecatapi.com/v1/images/search");
			const data = await res.json();
			output.innerHTML += `<div><img src="${data[0].url}" style="width:50%" alt="Cat!"></div>`;
			setTimeout(() => {
				window.scrollTo(0, document.body.scrollHeight);
			}, 200);
		},
	},
	help: {
		description: "display this help message",
		arguments: "",
		action: (_, output) => {
			let padding =
				Object.keys(commands)
					.map((cmd) => cmd.length + commands[cmd].arguments.length)
					.sort((a, b) => a - b)
					.reverse()[0] + 4;
			for (const cmd in commands) {
				output.innerHTML += `<div>${`<span style="color:#808080">${cmd + " " + commands[cmd].arguments}</span>` + " ".repeat(padding - cmd.length - commands[cmd].arguments.length) + commands[cmd].description}</div>`;
			}
		},
	},
};

const hidden_commands = {
	pspsps: {
		action: (_, output) => {
			output.innerHTML += "meow";
		},
	},
};

export { commands, hidden_commands };
