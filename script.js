(async () => {
	const prompt = document.querySelector("#prompt");
	const output = document.querySelector("#output");
	const promptPrefix = "$ ";
	const res = await fetch("./data.json");
	const data = await res.json();

	const commands = {
		echo: {
			description: "display a line of text",
			arguments: "[args]...",
			call: (argv, output) => {
				output.innerHTML += `<div>${argv.slice(1).join(" ")}</div>`;
			},
		},
		clear: {
			description: "clear the terminal screen",
			arguments: "",
			call: (_, output) => {
				output.innerHTML = "";
			},
		},
		about: {
			description: "display info about me",
			arguments: "",
			call: (_, output) => {
				output.innerHTML += `<div>${data.about}</div>`;
			},
		},
		contact: {
			description: "display contact info",
			arguments: "",
			call: (_, output) => {
				output.innerHTML += `<div><a href="mailto:${data.contact.email}">󰇮 ${data.contact.email}</a></div>`;
				output.innerHTML += `<div><a href="phone:${data.contact.phone}"> ${data.contact.phone}</a></div>`;
				output.innerHTML += `<div><a href="${data.contact.github}"> ${data.contact.github}</a></div>`;
				output.innerHTML += `<div><a href="${data.contact.linkedin}"> ${data.contact.linkedin}</a></div>`;
			},
		},
		projects: {
			description: "display projects or details of a project",
			arguments: "[project]",
			call: (argv, output) => {
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
				let max_name_len = 0;
				for (const project of data.projects) max_name_len = Math.max(max_name_len, project.name.length);
				for (const project of data.projects) {
					output.innerHTML += `<div>${`<span style="color:#808080">${project.name}</span>` + " ".repeat(max_name_len - project.name.length + 4) + project.description}</div>`;
				}
			},
		},
		help: {
			description: "display this help message",
			arguments: "",
			call: (_, output) => {
				let max_len = 0;
				for (const cmd in commands) max_len = Math.max(max_len, cmd.length + commands[cmd].arguments.length);
				for (const cmd in commands) {
					output.innerHTML += `<div>${`<span style="color:#808080">${cmd + " " + commands[cmd].arguments}</span>` + " ".repeat(max_len - cmd.length - commands[cmd].arguments.length + 4) + commands[cmd].description}</div>`;
				}
			},
		},
	};

	const funny_commands = {
		pspsps: {
			call: (_, output) => {
				output.innerHTML += "meow";
			},
		},
		cat: {
			call: async (_, output) => {
				const res = await fetch("https://api.thecatapi.com/v1/images/search");
				const data = await res.json();
				output.innerHTML += `<div><img src="${data[0].url}" style="width:50%" alt="Cat!"></div>`;
			},
		},
	};

	window.onload = () => {
		prompt.setSelectionRange(promptPrefix.length, promptPrefix.length);
	};

	window.onkeydown = (event) => {
		if (event.key != "Control") prompt.focus();
	};

	output.innerHTML = "<div>type <span style='color: #808080'>help</span> to see all commands</div>";

	prompt.value = promptPrefix;

	prompt.addEventListener("click", () => {
		if (prompt.selectionStart < promptPrefix.length) {
			prompt.setSelectionRange(promptPrefix.length, promptPrefix.length);
		}
	});

	prompt.addEventListener("keydown", (event) => {
		const caretPos = prompt.selectionStart;
		if (event.key === "Backspace" && caretPos <= promptPrefix.length) {
			event.preventDefault();
		} else if (
			(event.key === "ArrowLeft" || event.key === "ArrowUp" || event.key === "Home") &&
			caretPos <= promptPrefix.length
		) {
			event.preventDefault();
		}
	});

	prompt.addEventListener("keydown", (event) => {
		if (event.key === "Enter") {
			output.innerHTML += `<div>${prompt.value}</div>`;
			argv = prompt.value
				.trim()
				.substring(2)
				.split(" ")
				.filter((arg) => arg.length > 0);
			if (Object.keys(commands).includes(argv[0])) commands[argv[0]].call(argv, output);
			else if (Object.keys(funny_commands).includes(argv[0])) funny_commands[argv[0]].call(argv, output);
			else if (argv.length != 0) output.innerHTML += `<div>command not found: ${argv[0]}</div>`;
			window.scrollTo(0, document.body.scrollHeight);
			prompt.value = promptPrefix;
		}
	});
})();
