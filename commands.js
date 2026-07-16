import data from "./data.js";

const commands = {
	about: {
		description: "display info about me",
		arguments: null,
		hidden: false,
		action: (_) => {
			return `<div>${data.about}</div>`;
		},
	},

	contact: {
		description: "display contact info",
		arguments: null,
		hidden: false,
		action: (_) => {
			let out = "";
			for (const contact of data.contact) {
				switch (contact.type) {
					case "mail":
						out += `<div>${contact.name}: <a href="mailto:${contact.body}">${contact.body}</a></div>`;
						break;
					case "link":
						out += `<div>${contact.name}: <a href="${contact.body}">${contact.body}</a></div>`;
						break;
				}
			}
			return out;
		},
	},

	projects: {
		description: "display projects or details of a project",
		arguments: "[project]",
		hidden: false,
		action: (argv) => {
			if (argv.length > 1) {
				const project = data.projects.find((p) => p.name === argv[1]);
				if (project === undefined) {
					return `<div>No project found with name '${argv[1]}'</div>`;
				}

				let out = "";
				out += `<div><span style="color:#808080">Neme:</span> ${project.name}</div>`;
				out += `<div><span style="color:#808080">Description:</span> ${project.description}</div>`;
				out += `<div><span style="color:#808080">Repository:</span> <a href="${project.repository}">${project.repository}</a></div>`;
				out += `<div><span style="color:#808080">Language:</span> ${project.language}</div>`;
				return out;
			}

			let maxNameLen =
				data.projects
					.map((proj) => proj.name.length)
					.sort()
					.reverse()[0] + 4;

			let out = "";
			for (const project of data.projects) {
				const name = `<a href="${project.repository}" style="color:#808080">${project.name}</a>`;
				const padding = " ".repeat(maxNameLen - project.name.length);
				const description = project.description;
				out += `<div>${name + padding + description}</div>`;
			}

			return out;
		},
	},

	resume: {
		description: "open to my resume",
		arguments: null,
		hidden: false,
		action: (_) => {
			window.location.href = "./ahmed_aboueleyoun_resume.pdf";
			return nul;
		},
	},

	echo: {
		description: "display a line of text",
		arguments: "[args]...",
		hidden: false,
		action: (argv) => {
			if (argv.slice(1).length == 0) {
				return "<div> </div>";
			}
			return `<div>${argv.slice(1).join(" ")}</div>`;
		},
	},

	clear: {
		description: "clear the terminal screen",
		arguments: null,
		hidden: false,
		action: (_) => {
			document.querySelector("#output").innerHTML = "";
			return null;
		},
	},

	cat: {
		description: "cat!",
		arguments: null,
		hidden: false,
		action: async (_) => {
			const res = await fetch("https://api.thecatapi.com/v1/images/search");
			const data = await res.json();
			return `<div><img src="${data[0].url}" style="height:25vw" alt="Cat!"></div>`;
		},
	},

	help: {
		description: "display this help message",
		arguments: null,
		hidden: false,
		action: (_) => {
			let maxUsageLen =
				Object.keys(commands)
					.map((cmd) => cmd.length + (commands[cmd].arguments?.length ?? 0))
					.sort((a, b) => a - b)
					.reverse()[0] + 2;

			let out = "";
			for (const cmd in commands) {
				if (commands[cmd].hidden) {
					continue;
				}

				const usage = `<span style="color:#808080">${cmd + " " + (commands[cmd].arguments ?? "")}</span>`;
				const padding = `<span>${" ".repeat(maxUsageLen - cmd.length - (commands[cmd].arguments?.length ?? 0))}</span>`;
				const description = commands[cmd].description;
				out += `<div>${usage + padding + description}</div>`;
			}

			return out;
		},
	},

	sudo: {
		description: null,
		arguments: null,
		hidden: true,
		action: (_) => {
			return "meow";
		},
	},

	ls: {
		description: null,
		arguments: null,
		hidden: true,
		action: (_) => {
			return [
				"fluffy_mittens.jpg",
				"garfield_the_menace.png",
				"nyan_cat_4k.webm",
				"cat_overlords_plan.txt",
				"void_cat_blackhole.gif",
				"toe_beans_closeup.jpeg",
				"cat_meme_final_final_v2.jpg",
				"keyboard_cat_2.0.mp4",
				"not_a_cat.exe",
				"lasagna_stealer.png",
				"cat_riding_roomba.mov",
				"404_cat_not_found.jpg",
			].join("  ");
		},
	},
};

export default commands;
