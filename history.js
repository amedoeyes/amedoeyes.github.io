class History {
	constructor() {
		this.entries = [];
		this.index = -1;
	}

	add(command) {
		if (this.entries[0] !== command) {
			this.entries.unshift(command);
		}
		this.index = -1;
	}

	prev() {
		if (this.index >= this.entries.length - 1) {
			return null;
		}

		this.index += 1;
		return this.entries[this.index];
	}

	next() {
		if (this.index > -1) {
			this.index -= 1;
		}

		if (this.index == -1) {
			return null;
		}

		return this.entries[this.index];
	}
}

export default History;
