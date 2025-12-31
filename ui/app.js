const app = document.getElementById("app");
const pageStage = document.getElementById("pageStage");
const spread = document.getElementById("spread");
const leftSlot = document.getElementById("leftSlot");
const rightSlot = document.getElementById("rightSlot");
const viewer = document.querySelector(".viewer");
const pageMeasure = document.getElementById("pageMeasure");
const closeBtn = document.getElementById("closeBtn");
const prevBtn = document.getElementById("prevBtn");
const nextBtn = document.getElementById("nextBtn");
const toolbarTitle = document.getElementById("toolbarTitle");

let locale = {};
let report = null;
let pages = [];
let spreads = [];
let currentSpreadIndex = 0;

function createEl(tag, className, text) {
	const el = document.createElement(tag);
	if (className) {
		el.className = className;
	}
	if (text !== undefined && text !== null) {
		el.textContent = text;
	}
	return el;
}

function placeholder() {
	return locale.placeholder_empty || "-";
}

function resolveDate(input) {
	if (input === undefined || input === null || input === "") {
		return null;
	}

	if (input instanceof Date) {
		return Number.isNaN(input.getTime()) ? null : input;
	}

	if (typeof input === "string") {
		const numeric = Number(input);
		if (!Number.isNaN(numeric)) {
			input = numeric;
		} else {
			const parsed = new Date(input);
			return Number.isNaN(parsed.getTime()) ? null : parsed;
		}
	}

	if (typeof input === "number") {
		const stamp = input > 1e12 ? input : input * 1000;
		const parsed = new Date(stamp);
		return Number.isNaN(parsed.getTime()) ? null : parsed;
	}

	return null;
}

function formatDate(timestamp, includeTime) {
	const date = resolveDate(timestamp);
	if (!date) {
		return placeholder();
	}

	const options = {
		year: "numeric",
		month: "short",
		day: "2-digit",
	};

	if (includeTime) {
		options.hour = "2-digit";
		options.minute = "2-digit";
	}

	return date.toLocaleString(undefined, options);
}

function setVisible(visible) {
	app.classList.toggle("is-visible", visible);
	app.setAttribute("aria-hidden", String(!visible));
	if (!visible) {
		leftSlot.replaceChildren();
		rightSlot.replaceChildren();
		pageMeasure.replaceChildren();
		pages = [];
		spreads = [];
		report = null;
		currentSpreadIndex = 0;
		spread.classList.remove("single");
		pageStage.classList.remove("single-view");
		viewer.classList.remove("single-view");
		updateIndicator();
	}
}

function buildBrandMark(label) {
	const brand = createEl("div", "brand-mark");
	const text = (label || "").replace(/\s+/g, "");
	if (!text) {
		return brand;
	}

	text.split("").forEach((char) => {
		brand.appendChild(createEl("span", "brand-letter", char));
	});

	return brand;
}

function buildTopItem(label, value, alignClass) {
	const wrapper = createEl("div", `header-topitem ${alignClass || ""}`.trim());
	wrapper.appendChild(createEl("div", "header-toplabel", label));
	wrapper.appendChild(
		createEl("div", "header-topvalue", value || placeholder())
	);
	return wrapper;
}

function buildHeader(reportData) {
	const header = createEl("div", "page-header");

	const topLine = createEl("div", "header-topline");

	// Ensure generated_at is properly formatted
	const generatedAtValue = formatDate(reportData.generated_at);
	const reportIdValue =
		(reportData.vehicle && reportData.vehicle.report_id) || placeholder();

	// Debug logging
	console.log("Building header:", {
		generatedAt: reportData.generated_at,
		generatedAtValue,
		reportIdValue,
		headerGeneratedLabel: locale.header_generated,
		headerReportIdLabel: locale.header_report_id,
	});

	// Build and append left item (generated date)
	const leftItem = buildTopItem(
		locale.header_generated,
		generatedAtValue,
		"left"
	);
	topLine.appendChild(leftItem);

	// Build and append center item (title)
	const centerItem = createEl("div", "center", locale.app_title);
	topLine.appendChild(centerItem);

	// Build and append right item (report ID)
	const rightItem = buildTopItem(
		locale.header_report_id,
		reportIdValue,
		"right"
	);
	topLine.appendChild(rightItem);

	console.log("TopLine children count:", topLine.children.length);

	const mainLine = createEl("div", "header-mainline");
	const brandStack = createEl("div");
	brandStack.appendChild(buildBrandMark(locale.brand_label));
	brandStack.appendChild(
		createEl("div", "header-subtitle", locale.app_subtitle)
	);

	const metaRows = [
		{ label: locale.header_vin, value: reportData.vehicle.vin },
		{ label: locale.header_plate, value: reportData.vehicle.plate },
		{
			label: locale.header_registration,
			value: reportData.vehicle.registration_label,
		},
	];

	const metaGrid = createEl("div", "meta-grid");
	metaRows.forEach((row) => {
		const label = createEl("div", "meta-label", row.label);
		const value = createEl("div", "meta-value", row.value || placeholder());
		metaGrid.appendChild(label);
		metaGrid.appendChild(value);
	});

	mainLine.appendChild(brandStack);
	mainLine.appendChild(metaGrid);

	header.appendChild(topLine);
	header.appendChild(mainLine);

	return header;
}

function createPage(reportData) {
	const page = createEl("div", "page");
	page.style.animationDelay = `${pages.length * 0.06}s`;

	const header = buildHeader(reportData);
	const body = createEl("div", "page-body");
	const footer = createEl("div", "page-footer");

	page.appendChild(header);
	page.appendChild(body);
	page.appendChild(footer);

	pageMeasure.appendChild(page);

	const pageBundle = { page, body, footer };
	pages.push(pageBundle);
	return pageBundle;
}

function isOverflow(body) {
	return body.scrollHeight > body.clientHeight + 2;
}

function createSectionSkeleton(sectionData) {
	const section = createEl("section", "section");
	section.appendChild(createEl("h2", "section-title", sectionData.title));

	if (!sectionData.rows || sectionData.rows.length === 0) {
		section.appendChild(
			createEl("div", "section-empty", sectionData.emptyText)
		);
		return { section, tbody: null };
	}

	const table = createEl("table", "table");
	const thead = createEl("thead");
	const headerRow = createEl("tr");

	sectionData.columns.forEach((column) => {
		const th = createEl("th", column.className || "", column.label);
		headerRow.appendChild(th);
	});

	thead.appendChild(headerRow);
	const tbody = createEl("tbody");
	table.appendChild(thead);
	table.appendChild(tbody);
	section.appendChild(table);

	return { section, tbody };
}

function buildRow(columns, rowData) {
	const row = createEl("tr");

	columns.forEach((column) => {
		const value = column.render(rowData);
		const cell = createEl(
			"td",
			column.className || "",
			value === undefined || value === null || value === ""
				? placeholder()
				: value
		);
		if (column.align === "right") {
			cell.classList.add("right");
		}
		if (column.muted) {
			cell.classList.add("muted");
		}
		row.appendChild(cell);
	});

	return row;
}

function appendSection(reportData, sectionData, currentPage) {
	let page = currentPage || createPage(reportData);
	let sectionBundle = createSectionSkeleton(sectionData);

	page.body.appendChild(sectionBundle.section);

	if (isOverflow(page.body)) {
		page.body.removeChild(sectionBundle.section);
		page = createPage(reportData);
		page.body.appendChild(sectionBundle.section);
	}

	if (!sectionBundle.tbody) {
		if (isOverflow(page.body)) {
			page.body.removeChild(sectionBundle.section);
			page = createPage(reportData);
			page.body.appendChild(sectionBundle.section);
		}

		return page;
	}

	for (let i = 0; i < sectionData.rows.length; i += 1) {
		const row = buildRow(sectionData.columns, sectionData.rows[i]);
		sectionBundle.tbody.appendChild(row);

		if (isOverflow(page.body)) {
			sectionBundle.tbody.removeChild(row);

			if (!sectionBundle.tbody.rows.length) {
				page.body.removeChild(sectionBundle.section);
			}

			page = createPage(reportData);
			sectionBundle = createSectionSkeleton(sectionData);
			page.body.appendChild(sectionBundle.section);
			sectionBundle.tbody.appendChild(row);
		}
	}

	return page;
}

function buildServiceSection(reportData) {
	const rows = reportData.services || [];
	const showIdentifiers =
		reportData.visibility && reportData.visibility.show_identifiers;
	const showMileage = rows.some(
		(row) => row.mileage !== null && row.mileage !== undefined
	);

	const columns = [
		{
			label: locale.table_type,
			render: (row) => row.label,
		},
		{
			label: locale.table_date,
			render: (row) => formatDate(row.created_at),
		},
	];

	if (showMileage) {
		columns.push({
			label: locale.table_mileage,
			align: "right",
			render: (row) => row.mileage,
		});
	}

	columns.push(
		{
			label: locale.table_shop,
			render: (row) => row.job_label,
		},
		{
			label: locale.table_notes,
			render: (row) => row.notes,
		}
	);

	if (showIdentifiers) {
		columns.push({
			label: locale.table_recorded_by,
			render: (row) => row.author_identifier || placeholder(),
		});
	}

	return {
		title: locale.section_service,
		rows,
		columns,
		emptyText: locale.empty_service,
	};
}

function buildIncidentSection(reportData) {
	const rows = reportData.incidents || [];
	const showIdentifiers =
		reportData.visibility && reportData.visibility.show_identifiers;
	const showVisibility = rows.some((row) => row.is_private);

	const columns = [
		{
			label: locale.table_type,
			render: (row) => row.label,
		},
		{
			label: locale.table_date,
			render: (row) => formatDate(row.created_at),
		},
		{
			label: locale.table_agency,
			render: (row) => row.job_label,
		},
		{
			label: locale.table_notes,
			render: (row) => row.notes,
		},
	];

	if (showVisibility) {
		columns.push({
			label: locale.table_visibility,
			render: (row) =>
				row.is_private ? locale.status_private : locale.status_public,
		});
	}

	if (showIdentifiers) {
		columns.push({
			label: locale.table_recorded_by,
			render: (row) => row.author_identifier || placeholder(),
		});
	}

	return {
		title: locale.section_incident,
		rows,
		columns,
		emptyText: locale.empty_incident,
	};
}

function buildOwnershipSection(reportData) {
	const rows = reportData.owners || [];

	const columns = [
		{
			label: locale.table_owner,
			render: (row) => row.owner_label,
		},
		{
			label: locale.table_transfer_date,
			render: (row) => formatDate(row.created_at),
		},
		{
			label: locale.table_registration,
			render: (row) => row.registration_label,
		},
		{
			label: locale.table_notes,
			render: (row) => row.notes || placeholder(),
		},
	];

	return {
		title: locale.section_ownership,
		rows,
		columns,
		emptyText: locale.empty_ownership,
	};
}

function updatePageNumbers() {
	const total = pages.length;
	pages.forEach((page, index) => {
		page.footer.textContent = `${locale.ui_page} ${index + 1} / ${total}`;
	});
}

function syncHeaderTopLine(reportData) {
	const generatedValue = formatDate(reportData.generated_at);
	const reportId = reportData.vehicle && reportData.vehicle.report_id;

	pages.forEach((pageBundle) => {
		const header = pageBundle.page.querySelector(".page-header");
		if (!header) {
			return;
		}

		const topLine = header.querySelector(".header-topline");
		if (!topLine) {
			return;
		}

		// Clear and rebuild the topline
		topLine.replaceChildren();

		// Always add all three items
		const leftItem = buildTopItem(
			locale.header_generated,
			generatedValue,
			"left"
		);
		const centerItem = createEl("div", "center", locale.app_title);
		const rightItem = buildTopItem(locale.header_report_id, reportId, "right");

		topLine.appendChild(leftItem);
		topLine.appendChild(centerItem);
		topLine.appendChild(rightItem);
	});
}

function createBlankPage() {
	return createEl("div", "page page-blank");
}

function buildSpreads() {
	spreads = [];

	const total = pages.length;
	if (!total) {
		return;
	}

	const lastIndex = total - 1;
	const isEven = total % 2 === 0;

	spreads.push({
		type: "single",
		left: null,
		right: pages[0].page,
		numbers: [1],
	});

	if (total === 1) {
		return;
	}

	if (isEven) {
		for (let i = 1; i < lastIndex; i += 2) {
			const leftPage = pages[i].page;
			const rightPage = pages[i + 1] ? pages[i + 1].page : createBlankPage();
			const numbers = pages[i + 1] ? [i + 1, i + 2] : [i + 1];

			spreads.push({
				type: "double",
				left: leftPage,
				right: rightPage,
				numbers,
			});
		}

		spreads.push({
			type: "single",
			left: null,
			right: pages[lastIndex].page,
			numbers: [total],
		});
	} else {
		for (let i = 1; i <= lastIndex; i += 2) {
			const leftPage = pages[i].page;
			const rightPage = pages[i + 1] ? pages[i + 1].page : createBlankPage();
			const numbers = pages[i + 1] ? [i + 1, i + 2] : [i + 1];

			spreads.push({
				type: "double",
				left: leftPage,
				right: rightPage,
				numbers,
			});
		}
	}
}

function animateSpread() {
	const prefersReduced = window.matchMedia(
		"(prefers-reduced-motion: reduce)"
	).matches;
	if (prefersReduced) {
		return;
	}

	const targets = [];
	if (leftSlot.firstElementChild) {
		targets.push(leftSlot.firstElementChild);
	}
	if (rightSlot.firstElementChild) {
		targets.push(rightSlot.firstElementChild);
	}

	targets.forEach((target) => {
		target.animate(
			[
				{ opacity: 0, transform: "translateY(10px)" },
				{ opacity: 1, transform: "translateY(0)" },
			],
			{ duration: 260, easing: "cubic-bezier(0.4, 0, 0.2, 1)" }
		);
	});
}

function updateIndicator() {
	const total = pages.length;
	if (!total || !spreads.length) {
		prevBtn.disabled = true;
		nextBtn.disabled = true;
		return;
	}

	prevBtn.disabled = currentSpreadIndex <= 0;
	nextBtn.disabled = currentSpreadIndex >= spreads.length - 1;
}

function renderSpread(animate) {
	leftSlot.replaceChildren();
	rightSlot.replaceChildren();

	const spreadData = spreads[currentSpreadIndex];
	if (!spreadData) {
		updateIndicator();
		return;
	}

	const isSingle = spreadData.type === "single";
	spread.classList.toggle("single", isSingle);
	pageStage.classList.toggle("single-view", isSingle);
	viewer.classList.toggle("single-view", isSingle);

	if (isSingle && spreadData.right) {
		spreadData.right.classList.add("page-single");
	} else {
		if (spreadData.left) {
			spreadData.left.classList.remove("page-single");
		}
		if (spreadData.right) {
			spreadData.right.classList.remove("page-single");
		}
	}

	console.log("Rendering spread:", {
		isSingle,
		currentSpreadIndex,
		spreadType: spreadData.type,
	});

	if (isSingle) {
		const page = spreadData.right;
		rightSlot.appendChild(page);

		// Debug: Check header after appending
		const header = page.querySelector(".page-header");
		const topLine = header ? header.querySelector(".header-topline") : null;
		console.log("Single page header check:", {
			hasHeader: !!header,
			hasTopLine: !!topLine,
			topLineChildren: topLine ? topLine.children.length : 0,
			topLineHTML: topLine ? topLine.innerHTML : "none",
		});
	} else {
		leftSlot.appendChild(spreadData.left);
		rightSlot.appendChild(spreadData.right);
	}

	if (animate) {
		animateSpread();
	}

	updateIndicator();
}

function navigateTo(index) {
	if (!spreads.length) {
		return;
	}

	const nextIndex = Math.max(0, Math.min(index, spreads.length - 1));
	if (nextIndex === currentSpreadIndex) {
		return;
	}

	currentSpreadIndex = nextIndex;
	renderSpread(true);
}

function renderReport(reportData) {
	leftSlot.replaceChildren();
	rightSlot.replaceChildren();
	pageMeasure.replaceChildren();
	pages = [];
	spreads = [];
	currentSpreadIndex = 0;

	if (!reportData) {
		return;
	}

	if (!reportData.generated_at) {
		reportData.generated_at = Math.floor(Date.now() / 1000);
	}

	toolbarTitle.textContent = locale.app_title;
	closeBtn.setAttribute("aria-label", locale.ui_close);
	prevBtn.setAttribute("aria-label", locale.ui_prev_page);
	nextBtn.setAttribute("aria-label", locale.ui_next_page);

	let currentPage = null;
	currentPage = appendSection(
		reportData,
		buildServiceSection(reportData),
		currentPage
	);
	currentPage = appendSection(
		reportData,
		buildIncidentSection(reportData),
		currentPage
	);
	appendSection(reportData, buildOwnershipSection(reportData), currentPage);

	syncHeaderTopLine(reportData);
	updatePageNumbers();
	buildSpreads();
	requestAnimationFrame(() => {
		currentSpreadIndex = 0;
		renderSpread(false);
	});
}

function sendClose() {
	const resource = GetParentResourceName();
	fetch(`https://${resource}/${resource}:close`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json; charset=UTF-8",
		},
		body: JSON.stringify({}),
	});
}

closeBtn.addEventListener("click", () => {
	sendClose();
});

prevBtn.addEventListener("click", () => {
	navigateTo(currentSpreadIndex - 1);
});

nextBtn.addEventListener("click", () => {
	navigateTo(currentSpreadIndex + 1);
});

window.addEventListener("keydown", (event) => {
	if (event.key === "Escape") {
		sendClose();
	}

	if (event.key === "ArrowLeft") {
		navigateTo(currentSpreadIndex - 1);
	}

	if (event.key === "ArrowRight") {
		navigateTo(currentSpreadIndex + 1);
	}
});

window.addEventListener("resize", () => {
	updateIndicator();
	renderSpread(false);
});

window.addEventListener("message", (event) => {
	const data = event.data;
	if (!data || !data.type) {
		return;
	}

	if (data.type === "open") {
		locale = data.locale || {};
		report = data.report || null;
		document.title = locale.app_title || "";
		renderReport(report);
		setVisible(true);
	}

	if (data.type === "close") {
		setVisible(false);
	}
});
