from __future__ import annotations

import html
import re
from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    PageTemplate,
    Paragraph,
    Preformatted,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "CertaSurv_Company_Field_Operations_Handbook.md"
OUTPUT_DIR = ROOT / "output" / "pdf"
PDF_PATH = OUTPUT_DIR / "CertaSurv_Field_Onboarding_Book.pdf"
LOGO_PATH = Path(r"C:\Users\SimpS\OneDrive\Pictures\CertaSurv Without Slogan 2400x1800.png")


BRAND_NAVY = colors.HexColor("#2A2F35")
BRAND_GREEN = colors.HexColor("#47704B")
BRAND_GOLD = colors.HexColor("#C7902C")
INK = colors.HexColor("#20262E")
MUTED = colors.HexColor("#5C6875")
LIGHT_BLUE = colors.HexColor("#EAF1F7")
LIGHT_GREEN = colors.HexColor("#EDF7F1")
LIGHT_GOLD = colors.HexColor("#FAF2DF")
GRID = colors.HexColor("#D7DEE6")


def xml(text: str) -> str:
    return html.escape(text, quote=False)


def inline_markup(text: str) -> str:
    escaped = xml(text)
    return re.sub(r"`([^`]+)`", r"<font name='Courier'>\1</font>", escaped)


def plain_heading(text: str) -> str:
    return re.sub(r"^\d+\.\s*", "", text).strip()


class HandbookDocTemplate(BaseDocTemplate):
    def __init__(self, filename: str, **kwargs):
        super().__init__(filename, **kwargs)
        self._heading_index = 0

    def beforeDocument(self):
        self._heading_index = 0

    def afterFlowable(self, flowable):
        style = getattr(flowable, "style", None)
        if not style:
            return
        if style.name not in {"BookChapter", "SectionHeading", "SubHeading"}:
            return
        text = getattr(flowable, "getPlainText", lambda: "")()
        if not text:
            return
        level = {"BookChapter": 0, "SectionHeading": 1, "SubHeading": 2}[style.name]
        self._heading_index += 1
        key = f"h{self._heading_index}"
        self.canv.bookmarkPage(key)
        self.notify("TOCEntry", (level, text, self.page, key))


def make_styles():
    base = getSampleStyleSheet()
    styles = {}
    styles["CoverBrand"] = ParagraphStyle(
        "CoverBrand",
        parent=base["Title"],
        fontName="Helvetica-Bold",
        fontSize=22,
        leading=26,
        alignment=TA_CENTER,
        textColor=colors.white,
        spaceAfter=14,
    )
    styles["CoverTitle"] = ParagraphStyle(
        "CoverTitle",
        parent=base["Title"],
        fontName="Helvetica-Bold",
        fontSize=24,
        leading=30,
        alignment=TA_CENTER,
        textColor=colors.white,
        spaceAfter=18,
    )
    styles["CoverSub"] = ParagraphStyle(
        "CoverSub",
        parent=base["Normal"],
        fontName="Helvetica",
        fontSize=11,
        leading=16,
        alignment=TA_CENTER,
        textColor=colors.HexColor("#DDEAF3"),
    )
    styles["BookChapter"] = ParagraphStyle(
        "BookChapter",
        parent=base["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=20,
        leading=24,
        textColor=BRAND_NAVY,
        spaceBefore=18,
        spaceAfter=10,
        keepWithNext=True,
    )
    styles["SectionHeading"] = ParagraphStyle(
        "SectionHeading",
        parent=base["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=14,
        leading=18,
        textColor=BRAND_GREEN,
        spaceBefore=13,
        spaceAfter=6,
        keepWithNext=True,
    )
    styles["SubHeading"] = ParagraphStyle(
        "SubHeading",
        parent=base["Heading3"],
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=14,
        textColor=BRAND_NAVY,
        spaceBefore=9,
        spaceAfter=4,
        keepWithNext=True,
    )
    styles["Body"] = ParagraphStyle(
        "Body",
        parent=base["BodyText"],
        fontName="Helvetica",
        fontSize=9.5,
        leading=13.5,
        textColor=INK,
        spaceAfter=6,
    )
    styles["Small"] = ParagraphStyle(
        "Small",
        parent=styles["Body"],
        fontSize=8,
        leading=10.5,
        textColor=MUTED,
    )
    styles["Bullet"] = ParagraphStyle(
        "Bullet",
        parent=styles["Body"],
        leftIndent=13,
        firstLineIndent=-7,
        bulletIndent=0,
        spaceAfter=3,
    )
    styles["Numbered"] = ParagraphStyle(
        "Numbered",
        parent=styles["Body"],
        leftIndent=18,
        firstLineIndent=-12,
        bulletIndent=0,
        spaceAfter=3,
    )
    styles["Code"] = ParagraphStyle(
        "Code",
        parent=base["Code"],
        fontName="Courier",
        fontSize=8,
        leading=10,
        backColor=colors.HexColor("#F4F6F8"),
        borderColor=GRID,
        borderWidth=0.25,
        borderPadding=5,
        spaceBefore=4,
        spaceAfter=8,
    )
    styles["Callout"] = ParagraphStyle(
        "Callout",
        parent=styles["Body"],
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=14,
        textColor=BRAND_NAVY,
        backColor=LIGHT_GOLD,
        borderColor=BRAND_GOLD,
        borderWidth=0.75,
        borderPadding=7,
        spaceBefore=6,
        spaceAfter=9,
    )
    styles["TOCTitle"] = ParagraphStyle(
        "TOCTitle",
        parent=styles["BookChapter"],
        alignment=TA_LEFT,
        spaceAfter=16,
    )
    return styles


def on_page(canvas, doc):
    width, height = letter
    if doc.page == 1:
        canvas.saveState()
        canvas.setFillColor(BRAND_GREEN)
        canvas.rect(0, 0, width, height, fill=1, stroke=0)
        if LOGO_PATH.exists():
            logo = ImageReader(str(LOGO_PATH))
            logo_w = 7.1 * inch
            logo_h = logo_w * 0.75
            canvas.drawImage(
                logo,
                (width - logo_w) / 2,
                height - 1.02 * inch - logo_h,
                width=logo_w,
                height=logo_h,
                preserveAspectRatio=True,
                mask="auto",
            )
        canvas.setFillColor(colors.HexColor("#385B3E"))
        canvas.rect(0, 0, width, 0.9 * inch, fill=1, stroke=0)
        canvas.setFillColor(BRAND_GOLD)
        canvas.rect(0, 0.9 * inch, width, 0.08 * inch, fill=1, stroke=0)
        canvas.setStrokeColor(colors.white)
        canvas.setLineWidth(1.2)
        canvas.line(0.85 * inch, 2.15 * inch, width - 0.85 * inch, 2.15 * inch)
        canvas.restoreState()
        return

    canvas.saveState()
    canvas.setFillColor(BRAND_NAVY)
    canvas.rect(0, height - 0.44 * inch, width, 0.44 * inch, fill=1, stroke=0)
    canvas.setFont("Helvetica-Bold", 8)
    canvas.setFillColor(colors.white)
    canvas.drawString(0.58 * inch, height - 0.28 * inch, "CertaSurv Field Onboarding Book")
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(width - 0.58 * inch, height - 0.28 * inch, f"Page {doc.page}")
    canvas.setStrokeColor(BRAND_GREEN)
    canvas.setLineWidth(0.8)
    canvas.line(0.58 * inch, 0.52 * inch, width - 0.58 * inch, 0.52 * inch)
    canvas.setFont("Helvetica", 7)
    canvas.setFillColor(MUTED)
    canvas.drawString(0.58 * inch, 0.34 * inch, "Internal onboarding draft - field direction, daily logs, codes, evidence, and office handoff.")
    canvas.restoreState()


def paragraph(text: str, styles, style_name: str = "Body"):
    return Paragraph(inline_markup(text), styles[style_name])


def add_bullets(story, items, styles):
    for item in items:
        story.append(Paragraph(inline_markup(f"- {item}"), styles["Bullet"]))
    story.append(Spacer(1, 0.05 * inch))


def add_checklist(story, title: str, items, styles):
    story.append(Paragraph(xml(title), styles["SubHeading"]))
    rows = [["Done", "Item"]]
    for item in items:
        rows.append(["[  ]", item])
    table = Table(rows, colWidths=[0.55 * inch, 6.15 * inch], hAlign="LEFT", repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), BRAND_NAVY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("LEADING", (0, 0), (-1, -1), 10),
                ("GRID", (0, 0), (-1, -1), 0.25, GRID),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.append(table)
    story.append(Spacer(1, 0.12 * inch))


def add_key_value_table(story, rows, styles, col_widths=None):
    data = [[Paragraph(f"<b>{xml(a)}</b>", styles["Small"]), Paragraph(inline_markup(b), styles["Small"])] for a, b in rows]
    table = Table(data, colWidths=col_widths or [1.65 * inch, 5.05 * inch], hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), LIGHT_BLUE),
                ("BACKGROUND", (1, 0), (1, -1), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.25, GRID),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    story.append(table)
    story.append(Spacer(1, 0.12 * inch))


def add_front_matter(story, styles):
    story.append(Spacer(1, 6.15 * inch))
    story.append(Paragraph("Field Operations Onboarding Book", styles["CoverTitle"]))
    story.append(Paragraph("Field direction, daily logs, survey codes, evidence capture, and office handoff.", styles["CoverSub"]))
    story.append(Spacer(1, 0.64 * inch))
    story.append(Paragraph("Prepared for internal onboarding", styles["CoverSub"]))
    story.append(Paragraph(f"Working draft - {date.today().isoformat()}", styles["CoverSub"]))
    story.append(PageBreak())

    story.append(Paragraph("How To Use This Book", styles["BookChapter"]))
    story.append(
        paragraph(
            "This onboarding book gives new CertaSurv field and office staff the operating rules they need before they touch a live job. It is built from the current company field procedure draft, Operations Hub structure, Apps Script/AppSheet standards, Drive rules, email direction, and field-office intent capture notes.",
            styles,
        )
    )
    story.append(Paragraph("The core expectation", styles["SubHeading"]))
    story.append(
        paragraph(
            "No field work should depend on private memory, isolated text messages, or a one-off phone call. Every instruction becomes a captured direction, every field day becomes a daily log, and every deliverable traces back to a job row, file, and evidence trail.",
            styles,
            "Callout",
        )
    )
    add_bullets(
        story,
        [
            "New crew members should read Chapters 1 through 8 before their first field day.",
            "Office/admin staff should focus on field direction, source-of-truth rules, Drive standards, and handoff gates.",
            "Drafters and reviewers should focus on Ed direction capture, point/source preservation, feature codes, and office review.",
            "Managers should use the checklists to audit whether the workflow is actually being followed.",
        ],
        styles,
    )
    story.append(Paragraph("First Week Roadmap", styles["SectionHeading"]))
    add_key_value_table(
        story,
        [
            ("Day 1", "Read source-of-truth rules, roles, field direction format, daily log format, and Drive folder basics."),
            ("Day 2", "Shadow a field package handoff. Confirm how CSD Project ID, work order, map, files, and photos connect."),
            ("Day 3", "Practice filling a field direction and daily log using a completed job. Do not use live data until reviewed."),
            ("Day 4", "Learn F/S point handling, photo numbering, required uploads, and stop-work signals."),
            ("Day 5", "Review Ed direction examples, callout codes, feature codes, and office handoff checklist."),
        ],
        styles,
    )
    story.append(PageBreak())

    story.append(Paragraph("Quick Reference", styles["BookChapter"]))
    story.append(Paragraph("Golden Rules", styles["SectionHeading"]))
    add_bullets(
        story,
        [
            "CSD Project ID is the permanent job key.",
            "No crew dispatch without a field direction record.",
            "No field day closes without a daily log.",
            "Private text, email, phone, marked-up drawing, and Google Chat direction must be captured into the job record.",
            "Use `Hold Until Confirmed` when scope, access, file, control, or approval is not ready.",
            "Field evidence must include photos, raw collector files, control notes, and return-trip notes when applicable.",
            "Reviewer decisions create deliverable truth; model outputs and field evidence support that decision.",
        ],
        styles,
    )
    story.append(Paragraph("Direction Callout Codes", styles["SectionHeading"]))
    add_key_value_table(
        story,
        [
            ("FIELD", "Something the crew must do, verify, photograph, set, recover, or avoid."),
            ("OFFICE", "Something the office must draft, label, review, price, map, or prepare."),
            ("VERIFY", "Something uncertain that needs proof before it becomes a deliverable fact."),
            ("CHANGE", "A correction to scope, linework, labels, deliverable type, or priority."),
            ("EVIDENCE", "Photos, documents, files, screenshots, marked-up drawings, calls, or emails that prove intent."),
            ("HELP", "Survey reasoning that explains why the instruction matters."),
            ("QUESTION", "A pending issue that needs an answer before action."),
            ("DECISION", "A reviewer or manager call that should become the working standard for that job."),
            ("DELIVER", "A final output request or release instruction."),
        ],
        styles,
    )
    story.append(Paragraph("Field Day Closeout", styles["SectionHeading"]))
    add_checklist(
        story,
        "Before leaving the site",
        [
            "Required shots and evidence collected.",
            "Found/set points photographed and numbered.",
            "Control check-in/check-out recorded.",
            "Raw file, photos, sketches, and notes uploaded or queued for upload.",
            "Daily log answers office questions before leaving.",
            "Return-trip risk marked yes/no with reason.",
            "Stop-work or scope-change issue escalated when needed.",
        ],
        styles,
    )
    story.append(PageBreak())


def markdown_table(lines, styles):
    parsed = []
    for line in lines:
        stripped = line.strip().strip("|")
        parsed.append([cell.strip() for cell in stripped.split("|")])
    if len(parsed) >= 2 and all(re.fullmatch(r":?-{3,}:?", cell.strip()) for cell in parsed[1]):
        parsed = [parsed[0]] + parsed[2:]
    max_cols = max(len(row) for row in parsed)
    for row in parsed:
        while len(row) < max_cols:
            row.append("")

    table_width = 6.9 * inch
    if max_cols == 2:
        col_widths = [2.1 * inch, table_width - 2.1 * inch]
    elif max_cols == 3:
        col_widths = [1.65 * inch, 2.8 * inch, table_width - 4.45 * inch]
    else:
        col_widths = [table_width / max_cols] * max_cols

    data = [[Paragraph(inline_markup(cell), styles["Small"]) for cell in row] for row in parsed]
    table = Table(data, colWidths=col_widths, hAlign="LEFT", repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), BRAND_NAVY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("GRID", (0, 0), (-1, -1), 0.25, GRID),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table


def flush_paragraph(story, buffer, styles):
    if not buffer:
        return
    text = " ".join(part.strip() for part in buffer if part.strip())
    if text:
        story.append(paragraph(text, styles))
    buffer.clear()


def flush_table(story, table_lines, styles):
    if not table_lines:
        return
    story.append(markdown_table(table_lines, styles))
    story.append(Spacer(1, 0.1 * inch))
    table_lines.clear()


def parse_markdown_into_story(path: Path, story, styles):
    lines = path.read_text(encoding="utf-8").splitlines()
    paragraph_buffer = []
    table_lines = []
    code_lines = []
    in_code = False
    skip_original_title = True

    def flush_all():
        flush_paragraph(story, paragraph_buffer, styles)
        flush_table(story, table_lines, styles)

    for raw in lines:
        line = raw.rstrip()

        if line.startswith("```"):
            flush_all()
            if in_code:
                story.append(Preformatted("\n".join(code_lines), styles["Code"]))
                code_lines.clear()
                in_code = False
            else:
                in_code = True
            continue

        if in_code:
            code_lines.append(line)
            continue

        if skip_original_title and line.startswith("# "):
            skip_original_title = False
            continue

        if line.startswith("Draft date:") or line.startswith("Status:"):
            continue

        if not line.strip():
            flush_all()
            story.append(Spacer(1, 0.04 * inch))
            continue

        if line.strip().startswith("|") and "|" in line.strip()[1:]:
            flush_paragraph(story, paragraph_buffer, styles)
            table_lines.append(line)
            continue

        flush_table(story, table_lines, styles)

        match = re.match(r"^(#{1,3})\s+(.*)$", line)
        if match:
            flush_paragraph(story, paragraph_buffer, styles)
            hashes, title = match.groups()
            title = plain_heading(title)
            if len(hashes) == 1:
                story.append(Paragraph(inline_markup(title), styles["BookChapter"]))
            elif len(hashes) == 2:
                story.append(Paragraph(inline_markup(title), styles["BookChapter"]))
            else:
                story.append(Paragraph(inline_markup(title), styles["SectionHeading"]))
            continue

        bullet = re.match(r"^-\s+(.*)$", line)
        if bullet:
            flush_paragraph(story, paragraph_buffer, styles)
            story.append(Paragraph(inline_markup(f"- {bullet.group(1)}"), styles["Bullet"]))
            continue

        numbered = re.match(r"^(\d+)\.\s+(.*)$", line)
        if numbered:
            flush_paragraph(story, paragraph_buffer, styles)
            story.append(Paragraph(inline_markup(f"{numbered.group(1)}. {numbered.group(2)}"), styles["Numbered"]))
            continue

        paragraph_buffer.append(line)

    flush_all()
    if code_lines:
        story.append(Preformatted("\n".join(code_lines), styles["Code"]))


def add_appendices(story, styles):
    story.append(PageBreak())
    story.append(Paragraph("Onboarding Signoff", styles["BookChapter"]))
    story.append(
        paragraph(
            "Use this page as the first-pass training acknowledgement. It is not a legal HR policy by itself; it confirms that the employee has been shown the current field operating system.",
            styles,
        )
    )
    add_checklist(
        story,
        "Employee has reviewed",
        [
            "Source-of-truth rules and project ID standard.",
            "Field direction format and callout codes.",
            "Daily log completion standard.",
            "Required files, photos, raw data, and closeout gates.",
            "Stop-work and escalation process.",
            "F/S point handling and photo numbering.",
            "Feature code standard and alias cleanup rules.",
            "Drive folder and file naming rules.",
            "Office review and QA handoff expectations.",
        ],
        styles,
    )
    story.append(Spacer(1, 0.18 * inch))
    data = [
        ["Employee name", ""],
        ["Trainer", ""],
        ["Date", ""],
        ["Notes / restrictions", ""],
    ]
    table = Table(data, colWidths=[1.55 * inch, 5.15 * inch], rowHeights=[0.36 * inch, 0.36 * inch, 0.36 * inch, 0.75 * inch])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), LIGHT_GREEN),
                ("GRID", (0, 0), (-1, -1), 0.4, GRID),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    story.append(table)


def build_pdf():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    styles = make_styles()
    frame = Frame(0.58 * inch, 0.68 * inch, 7.34 * inch, 9.78 * inch, leftPadding=0, bottomPadding=0, rightPadding=0, topPadding=0)
    doc = HandbookDocTemplate(
        str(PDF_PATH),
        pagesize=letter,
        leftMargin=0.58 * inch,
        rightMargin=0.58 * inch,
        topMargin=0.62 * inch,
        bottomMargin=0.68 * inch,
        title="CertaSurv Field Operations Onboarding Book",
        author="CertaSurv",
    )
    doc.addPageTemplates([PageTemplate(id="normal", frames=[frame], onPage=on_page)])

    story = []
    add_front_matter(story, styles)

    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle(name="TOC0", fontName="Helvetica-Bold", fontSize=10, leading=13, leftIndent=0, firstLineIndent=0, spaceBefore=5),
        ParagraphStyle(name="TOC1", fontName="Helvetica", fontSize=8.5, leading=11, leftIndent=14, firstLineIndent=0),
        ParagraphStyle(name="TOC2", fontName="Helvetica", fontSize=8, leading=10, leftIndent=28, firstLineIndent=0, textColor=MUTED),
    ]
    story.append(Paragraph("Table Of Contents", styles["TOCTitle"]))
    story.append(toc)
    story.append(PageBreak())

    story.append(Paragraph("Company Field Operations Handbook", styles["BookChapter"]))
    story.append(
        paragraph(
            "The following chapters are the operating standard gathered from the current field procedure draft and related CertaSurv source material. Use them as the onboarding reference and update them as company procedures mature.",
            styles,
        )
    )
    parse_markdown_into_story(SOURCE, story, styles)
    add_appendices(story, styles)
    doc.multiBuild(story)
    return PDF_PATH


if __name__ == "__main__":
    print(build_pdf())
