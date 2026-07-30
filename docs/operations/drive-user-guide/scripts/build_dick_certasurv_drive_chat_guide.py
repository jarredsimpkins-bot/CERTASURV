from __future__ import annotations

from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.platypus import (
    BaseDocTemplate,
    Flowable,
    Frame,
    KeepTogether,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "pdf" / "Dick_CERTASURV_Drive_and_Chat_Guide_improved.pdf"

DRIVE_URL = "https://drive.google.com/drive/folders/0ALDrNUPuW8smUk9PVA"
MAIL_URL = "https://mail.google.com/"
CHAT_URL = "https://chat.google.com/"
DRIVE_DOWNLOAD_URL = "https://www.google.com/drive/download/"
CHAT_INSTALL_URL = "https://support.google.com/chat/answer/9455386?hl=en"
DRIVE_HELP_URL = "https://support.google.com/drive/answer/10838124?hl=en"

PAGE_W, PAGE_H = letter
MARGIN_X = 0.65 * inch
MARGIN_TOP = 0.72 * inch
MARGIN_BOTTOM = 0.58 * inch
CONTENT_W = PAGE_W - (2 * MARGIN_X)

NAVY = colors.HexColor("#173a63")
INK = colors.HexColor("#20242a")
MUTED = colors.HexColor("#5a6675")
LINE = colors.HexColor("#cfd8e3")
SOFT_BLUE = colors.HexColor("#eef5fb")
TEAL = colors.HexColor("#0b7d82")
GREEN = colors.HexColor("#2d7d33")
BLUE = colors.HexColor("#245682")
ORANGE = colors.HexColor("#bd5b00")
SOFT_ORANGE = colors.HexColor("#fff4e6")
RED = colors.HexColor("#b71c1c")
SOFT_RED = colors.HexColor("#fdeaea")
SOFT_GREEN = colors.HexColor("#edf7ee")


styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        "GuideTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=22,
        leading=25,
        textColor=colors.white,
        alignment=TA_CENTER,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        "GuideSubtitle",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=12,
        leading=15,
        textColor=colors.HexColor("#dfeaf5"),
        alignment=TA_CENTER,
    )
)
styles.add(
    ParagraphStyle(
        "H1",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=19,
        leading=23,
        textColor=NAVY,
        spaceBefore=6,
        spaceAfter=6,
    )
)
styles.add(
    ParagraphStyle(
        "H2",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=13.8,
        leading=16.5,
        textColor=NAVY,
        spaceBefore=10,
        spaceAfter=5,
    )
)
styles.add(
    ParagraphStyle(
        "Body",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=9.7,
        leading=12.6,
        textColor=INK,
        spaceAfter=5,
    )
)
styles.add(
    ParagraphStyle(
        "Small",
        parent=styles["Body"],
        fontSize=8.5,
        leading=10.8,
        textColor=MUTED,
        spaceAfter=0,
    )
)
styles.add(
    ParagraphStyle(
        "Label",
        parent=styles["Body"],
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=12,
        textColor=NAVY,
        spaceAfter=2,
    )
)
styles.add(
    ParagraphStyle(
        "HeaderCell",
        parent=styles["Label"],
        fontName="Helvetica-Bold",
        fontSize=9.5,
        leading=11.5,
        textColor=colors.white,
        spaceAfter=0,
    )
)
styles.add(
    ParagraphStyle(
        "Step",
        parent=styles["Body"],
        fontSize=9.3,
        leading=11.6,
        spaceAfter=0,
    )
)
styles.add(
    ParagraphStyle(
        "Path",
        parent=styles["Body"],
        fontName="Courier",
        fontSize=8.15,
        leading=10,
        textColor=INK,
        spaceAfter=0,
    )
)
styles.add(
    ParagraphStyle(
        "Button",
        parent=styles["Body"],
        fontName="Helvetica-Bold",
        fontSize=10.2,
        leading=11.2,
        textColor=colors.white,
        alignment=TA_CENTER,
        spaceAfter=0,
    )
)
styles.add(
    ParagraphStyle(
        "ButtonSmall",
        parent=styles["Small"],
        fontName="Helvetica",
        fontSize=7.2,
        leading=8,
        textColor=colors.white,
        alignment=TA_CENTER,
        spaceAfter=0,
    )
)
styles.add(
    ParagraphStyle(
        "GuideBullet",
        parent=styles["Body"],
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=1.5,
    )
)


def p(text: str, style: str = "Body") -> Paragraph:
    return Paragraph(text, styles[style])


def bold(text: str) -> str:
    return f"<b>{escape(text)}</b>"


def code(text: str) -> str:
    return f"<font name='Courier' size='8.7'>{escape(text)}</font>"


def link(label: str, url: str) -> str:
    return f"<link href='{escape(url)}'><u>{escape(label)}</u></link>"


def section_title(num: int, title: str, subtitle: str | None = None) -> list:
    rows = [[p(f"{num}. {escape(title)}", "H1")]]
    items = [Table(rows, colWidths=[CONTENT_W], style=[("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 0), ("BOTTOMPADDING", (0, 0), (-1, -1), 0)])]
    if subtitle:
        items.append(p(escape(subtitle), "Small"))
    return items


def bullet_items(items: list[str]) -> list[Paragraph]:
    return [p(f"- {item}", "GuideBullet") for item in items]


def wrap_path(parts: list[str], limit: int = 78) -> str:
    lines: list[str] = []
    current = ""
    for part in parts:
        next_part = escape(part)
        if not current:
            current = next_part
            continue
        candidate = f"{current} &gt; {next_part}"
        if len(candidate.replace("&gt;", ">")) > limit:
            lines.append(current)
            current = f"&gt; {next_part}"
        else:
            current = candidate
    if current:
        lines.append(current)
    return "<br/>".join(lines)


def path_box(label: str, parts: list[str], border=BLUE, fill=SOFT_BLUE, note: str | None = None) -> Table:
    body = [p(escape(label), "Label"), p(wrap_path(parts), "Path")]
    if note:
        body.append(Spacer(1, 3))
        body.append(p(escape(note), "Small"))
    table = Table([[body]], colWidths=[CONTENT_W])
    table.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 1.1, border),
                ("BACKGROUND", (0, 0), (-1, -1), fill),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return table


def callout(title: str, body: str, border=ORANGE, fill=SOFT_ORANGE) -> Table:
    table = Table([[p(escape(title), "Label"), p(body, "Body")]], colWidths=[1.55 * inch, CONTENT_W - 1.55 * inch])
    table.setStyle(
        TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 1, border),
                ("BACKGROUND", (0, 0), (-1, -1), fill),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )
    return table


def link_buttons(buttons: list[tuple[str, str, str, colors.Color]]) -> Table:
    cells = []
    width = CONTENT_W / len(buttons)
    for label, url_short, url, color in buttons:
        label_text = f"<link href='{escape(url)}'><font color='white'><b>{escape(label)}</b></font><br/><font size='7.2' color='white'>{escape(url_short)}</font></link>"
        cells.append(Paragraph(label_text, styles["Button"]))
    table = Table([cells], colWidths=[width] * len(buttons), rowHeights=[0.48 * inch])
    commands = [
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]
    for idx, (_, _, _, color) in enumerate(buttons):
        commands.append(("BACKGROUND", (idx, 0), (idx, 0), color))
    table.setStyle(TableStyle(commands))
    return table


def steps(rows: list[tuple[str, str]]) -> Table:
    data = []
    for idx, (lead, detail) in enumerate(rows, 1):
        data.append(
            [
                p(str(idx), "Button"),
                p(f"{bold(lead)} - {escape(detail)}", "Step"),
            ]
        )
    table = Table(data, colWidths=[0.42 * inch, CONTENT_W - 0.42 * inch], hAlign="LEFT")
    commands = [
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("BACKGROUND", (0, 0), (0, -1), TEAL),
        ("TEXTCOLOR", (0, 0), (0, -1), colors.white),
        ("BACKGROUND", (1, 0), (1, -1), SOFT_BLUE),
        ("BOX", (1, 0), (1, -1), 0.4, LINE),
        ("LEFTPADDING", (0, 0), (0, -1), 0),
        ("RIGHTPADDING", (0, 0), (0, -1), 0),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (1, 0), (1, -1), 8),
        ("RIGHTPADDING", (1, 0), (1, -1), 8),
    ]
    for row in range(len(rows)):
        commands.append(("LINEBELOW", (0, row), (-1, row), 7, colors.white))
    table.setStyle(TableStyle(commands))
    return table


def data_table(headers: list[str], rows: list[list[str]], col_widths: list[float] | None = None) -> Table:
    data = [[p(escape(h), "HeaderCell") for h in headers]]
    for row in rows:
        data.append([p(cell, "Body") for cell in row])
    if col_widths is None:
        col_widths = [CONTENT_W / len(headers)] * len(headers)
    table = Table(data, colWidths=col_widths, repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), NAVY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.35, LINE),
                ("BACKGROUND", (0, 1), (-1, -1), colors.white),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f5f7fa")]),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


class TitleBand(Flowable):
    def __init__(self):
        super().__init__()
        self.width = CONTENT_W
        self.height = 1.48 * inch

    def draw(self):
        c = self.canv
        c.saveState()
        c.setFillColor(NAVY)
        c.rect(0, 0, self.width, self.height, fill=1, stroke=0)
        c.restoreState()
        title = p("DICK'S CERTASURV DRIVE AND CHAT GUIDE", "GuideTitle")
        subtitle = p("Company email, shared drive, parcel research, DWG and points, Drive for desktop, and Google Chat", "GuideSubtitle")
        _, title_h = title.wrapOn(c, self.width - 40, self.height)
        _, subtitle_h = subtitle.wrapOn(c, self.width - 54, self.height)
        total_h = title_h + 5 + subtitle_h
        top_y = (self.height + total_h) / 2
        title.drawOn(c, 20, top_y - title_h)
        subtitle.drawOn(c, 27, top_y - title_h - 5 - subtitle_h)


def top_rule(canvas, doc):
    page = canvas.getPageNumber()
    canvas.saveState()
    canvas.setStrokeColor(LINE)
    canvas.setLineWidth(0.7)
    canvas.line(MARGIN_X, PAGE_H - 0.42 * inch, PAGE_W - MARGIN_X, PAGE_H - 0.42 * inch)
    canvas.setFont("Helvetica-Bold", 8.7)
    canvas.setFillColor(NAVY)
    canvas.drawString(MARGIN_X, PAGE_H - 0.33 * inch, "CERTASURV PROJECT DRIVE")
    canvas.setFont("Helvetica", 8.5)
    canvas.setFillColor(MUTED)
    canvas.drawRightString(PAGE_W - MARGIN_X, PAGE_H - 0.33 * inch, "Guide for Dick")
    footer = f"Internal work guide | Folder structure reviewed July 22, 2026 | Page {page}"
    canvas.drawCentredString(PAGE_W / 2, 0.35 * inch, footer)
    canvas.restoreState()


def build_story() -> list:
    story: list = []
    story.append(TitleBand())
    story.append(Spacer(1, 12))
    story.append(p("Start Here", "H1"))
    story.append(
        steps(
            [
                ("Sign in", "Use the company Google account before opening Drive, Gmail, or Chat."),
                ("Open the shared drive", "In Google Drive, choose Shared drives, then open CERTASURV_PROJECT DRIVE."),
                ("Match the project", "Open the project folder that matches both the SSD job number and the address or project name."),
                ("Work inside the inner SSD folder", "Use the numbered workflow folders. Courthouse research is in 02; office drafting is in 04."),
            ]
        )
    )
    story.append(Spacer(1, 10))
    story.append(p("The Two Paths Used Most", "H2"))
    story.append(
        path_box(
            "Tax map parcel research",
            ["CERTASURV_PROJECT DRIVE", "[PROJECT]", "SSD", "02_COURTHOUSE_RESEARCH", "parcels", "[TAX MAP NUMBER]"],
            border=BLUE,
            fill=SOFT_BLUE,
            note="Use for courthouse screenshots, deeds, plats, tax maps, GIS images, and related parcel material.",
        )
    )
    story.append(Spacer(1, 7))
    story.append(
        path_box(
            "DWG and points",
            ["CERTASURV_PROJECT DRIVE", "[PROJECT]", "SSD", "04_OFFICE_DRAFTING", "02_BASE_FILES"],
            border=GREEN,
            fill=SOFT_GREEN,
            note="Use for the CAD drawing and the matching points file used for office work.",
        )
    )
    story.append(Spacer(1, 7))
    story.append(
        callout(
            "Folder correction",
            f"The live drive does <b>not</b> use {code('04 Courthouse > Files > Parcels')}. Use {code('02_COURTHOUSE_RESEARCH > parcels')} inside the selected project.",
        )
    )
    story.append(Spacer(1, 10))
    story.append(
        link_buttons(
            [
                ("OPEN COMPANY EMAIL", "mail.google.com", MAIL_URL, BLUE),
                ("OPEN PROJECT DRIVE", "project drive link", DRIVE_URL, GREEN),
                ("OPEN GOOGLE CHAT", "chat.google.com", CHAT_URL, TEAL),
            ]
        )
    )

    story.append(PageBreak())
    story.extend(section_title(1, "How The Shared Drive Is Organized", "Start at the shared drive, choose the correct project, then use the same numbered workflow folders inside that project."))
    story.append(Spacer(1, 5))
    story.append(path_box("Shared drive name", ["CERTASURV_PROJECT DRIVE"], note=f"Direct link: {DRIVE_URL}"))
    story.append(Spacer(1, 8))
    story.append(
        p(
            "At the root of the shared drive, most active jobs are project folders named with an SSD job number and a location. Examples include "
            f"{code('SSD-11643-RT35')} and {code('SSD-11641 - WINFIELD')}. The drive also contains system folders such as "
            f"{code('TEMPLATE')}, {code('ARCHIVE')}, {code('01FORMS')}, {code('ESTIMATES')}, and {code('00_CERTASURV_COMMAND_CENTER')}.",
            "Body",
        )
    )
    story.append(p("Standard Project Folder Tree", "H2"))
    story.append(
        path_box(
            "Open folders in this order",
            [
                "CERTASURV_PROJECT DRIVE",
                "[SSD-##### - PROJECT NAME OR ADDRESS]",
                "SSD",
                "01_INTAKE_SCOPE",
                "02_COURTHOUSE_RESEARCH",
                "03_FIELD_WORK",
                "04_OFFICE_DRAFTING",
                "05_REVIEW_QC",
                "06_DELIVERABLES",
            ],
        )
    )
    story.append(Spacer(1, 8))
    story.append(
        data_table(
            ["Folder", "Use"],
            [
                [code("01_INTAKE_SCOPE"), "Client intake, job scope, proposal information, and starting documents."],
                [code("02_COURTHOUSE_RESEARCH"), "Deeds, plats, tax maps, screenshots, parcel folders, and the master research log."],
                [code("03_FIELD_WORK"), "Crew instructions, raw field data, photos, sketches, line marking, control, and stakeout files."],
                [code("04_OFFICE_DRAFTING"), "Office notes, base files, DWG drawings, points, and exhibit PDFs."],
                [code("05_REVIEW_QC"), "Review and quality-control work before delivery."],
                [code("06_DELIVERABLES"), "Drafts and final deliverables."],
            ],
            [1.85 * inch, CONTENT_W - 1.85 * inch],
        )
    )
    story.append(Spacer(1, 8))
    story.append(callout("Rule", "For normal job work, open the correct SSD project folder. Do not work from TEMPLATE or ARCHIVE unless a supervisor specifically tells you to do so.", border=BLUE, fill=SOFT_BLUE))

    story.append(PageBreak())
    story.extend(section_title(2, "Find Courthouse And Parcel Files", "Parcel research is organized inside each project. Parcel folders are commonly named by the full tax map number."))
    story.append(Spacer(1, 5))
    story.append(path_box("Correct courthouse path", ["CERTASURV_PROJECT DRIVE", "[PROJECT]", "SSD", "02_COURTHOUSE_RESEARCH", "parcels", "[TAX MAP NUMBER]"]))
    story.append(Spacer(1, 9))
    story.append(p("Step By Step", "H2"))
    story.append(
        steps(
            [
                ("Open CERTASURV_PROJECT DRIVE", "Use Shared drives in Google Drive, or use the direct link in this guide."),
                ("Open the project folder", "Match both the SSD job number and the project name or address."),
                ("Open the inner SSD folder", "This is the standard working folder inside the project."),
                ("Open 02_COURTHOUSE_RESEARCH", "This is the courthouse, deed, plat, tax map, and parcel research area."),
                ("Open parcels", "In populated projects, this folder contains separate folders for individual parcels."),
                ("Open the exact tax map number", "Match the complete number, including leading zeros and the final suffix."),
            ]
        )
    )
    story.append(Spacer(1, 8))
    story.append(
        path_box(
            "Example parcel folder name",
            ["28-11-0050-0126-0000"],
            border=GREEN,
            fill=SOFT_GREEN,
            note="A parcel folder may contain courthouse screenshots, tax-map images, GIS images, deeds, plats, and related research.",
        )
    )
    story.append(Spacer(1, 7))
    story.append(p("Useful Courthouse Folders", "H2"))
    story.extend(
        bullet_items(
            [
                f"{code('00_MASTER_RESEARCH_LOG')} - overall research notes and tracking for the project.",
                f"{code('parcels')} - individual parcel folders, normally named by tax map number.",
                f"{code('plats')} - plat images or grouped plat material when that folder is present.",
            ]
        )
    )
    story.append(p("Search Tips", "H2"))
    story.extend(
        bullet_items(
            [
                "Search the shared drive using the full SSD job number when you cannot find the project.",
                "Search using the complete tax map number when a parcel folder is hard to spot.",
                "Double-check the project address before opening or downloading files from a similar job.",
            ]
        )
    )
    story.append(Spacer(1, 5))
    story.append(callout("Note", f"A new or lightly researched project may not have a {code('parcels')} folder yet. That usually means the parcel research has not been added or the material is still stored directly in {code('02_COURTHOUSE_RESEARCH')}.", border=LINE, fill=colors.HexColor("#f4f7fb")))

    story.append(PageBreak())
    story.extend(section_title(3, "Get The DWG And Points File", "The drawing and point data are stored in the office-drafting base-files folder for the selected project."))
    story.append(Spacer(1, 5))
    story.append(path_box("Correct DWG and points path", ["CERTASURV_PROJECT DRIVE", "[PROJECT]", "SSD", "04_OFFICE_DRAFTING", "02_BASE_FILES"], border=GREEN, fill=SOFT_GREEN))
    story.append(Spacer(1, 8))
    story.append(
        data_table(
            ["Type", "Typical extension", "Meaning"],
            [
                ["Drawing", code(".dwg"), "CAD drawing used by AutoCAD or compatible drafting software."],
                ["Points", f"{code('.csv')} or {code('.txt')}", "Survey point data. Populated base-files folders commonly include a CSV points file."],
            ],
            [1.25 * inch, 1.45 * inch, CONTENT_W - 2.7 * inch],
        )
    )
    story.append(Spacer(1, 8))
    story.append(p("Download From The Browser", "H2"))
    story.append(
        steps(
            [
                ("Open 02_BASE_FILES", "Confirm the folder is inside the correct project."),
                ("Download the DWG", "Right-click the drawing file and choose Download."),
                ("Download the points file", "Download the CSV, TXT, or other points file that belongs with the drawing."),
                ("Save them together", "Put both files in the same local job folder on the computer."),
                ("Open the local copies", "Use the approved CAD or point-processing software after the download finishes."),
            ]
        )
    )
    story.append(Spacer(1, 8))
    story.append(
        data_table(
            ["Before opening or sending, confirm", ""],
            [
                ["[ ] Correct SSD job number", "[ ] Correct project name or address"],
                ["[ ] Latest intended DWG version", "[ ] Matching points file downloaded"],
                ["[ ] Local copies saved together", "[ ] Source files left in place in Drive"],
            ],
            [CONTENT_W / 2, CONTENT_W / 2],
        )
    )
    story.append(Spacer(1, 8))
    story.append(callout("Protect the source files", "Download a copy. Do not move, rename, replace, or delete shared Drive files unless a supervisor specifically directs you to do that. When several versions exist, confirm which version is current before working.", border=RED, fill=SOFT_RED))

    story.append(PageBreak())
    story.extend(section_title(4, "Install And Use Drive For Desktop", "Drive for desktop puts Google Drive in Windows File Explorer or macOS Finder. The browser is still the safest choice for a one-time download."))
    story.append(Spacer(1, 5))
    story.append(
        link_buttons(
            [
                ("OPEN DRIVE IN BROWSER", "drive.google.com", "https://drive.google.com/", BLUE),
                ("OPEN PROJECT DRIVE", "project drive link", DRIVE_URL, GREEN),
                ("DOWNLOAD DRIVE FOR DESKTOP", "official download page", DRIVE_DOWNLOAD_URL, TEAL),
            ]
        )
    )
    story.append(Spacer(1, 10))
    story.append(p("Install And Sign In", "H2"))
    story.append(
        steps(
            [
                ("Open the official download page", "Use the Download Drive for desktop button above."),
                ("Run the installer", "On Windows, open GoogleDriveSetup.exe. On macOS, open GoogleDrive.dmg."),
                ("Follow the prompts", "Let the installer finish, then open Google Drive for desktop."),
                ("Sign in with company email", "Use the same company Google account that has access to the shared drive."),
                ("Open Shared drives", "In File Explorer or Finder, open Google Drive, then Shared drives."),
                ("Open CERTASURV_PROJECT DRIVE", "Choose the project, open SSD, and use the same numbered folders shown in this guide."),
            ]
        )
    )
    story.append(Spacer(1, 8))
    story.append(path_box("What the path looks like on the computer", ["Google Drive", "Shared drives", "CERTASURV_PROJECT DRIVE", "[PROJECT]", "SSD", "..."], border=BLUE, fill=SOFT_BLUE))
    story.append(Spacer(1, 8))
    story.append(p("Best Practice For DWG Work", "H2"))
    story.extend(
        bullet_items(
            [
                "Use Drive for desktop to find the file, but make a local working copy when directed by the office workflow.",
                "Keep the DWG and its points file together in the same local job folder.",
                "Do not drag shared-drive folders to another location. Dragging can move them for everyone if you have permission.",
                "When a file is only online, allow it to finish downloading before opening it in CAD software.",
            ]
        )
    )
    story.append(Spacer(1, 5))
    story.append(callout("Simple option", "For a one-time download, the browser method is usually safest: open Drive, right-click the file, choose Download, and save it locally.", border=GREEN, fill=SOFT_GREEN))

    story.append(PageBreak())
    story.extend(section_title(5, "Install Google Chat And Solve Common Problems", "Google Chat can be used in the browser or installed from Chrome as a desktop web app."))
    story.append(Spacer(1, 5))
    story.append(
        link_buttons(
            [
                ("OPEN GOOGLE CHAT", "chat.google.com", CHAT_URL, TEAL),
                ("OFFICIAL CHAT INSTALL GUIDE", "Google Chat Help", CHAT_INSTALL_URL, BLUE),
                ("OPEN COMPANY EMAIL", "mail.google.com", MAIL_URL, GREEN),
            ]
        )
    )
    story.append(Spacer(1, 10))
    story.append(p("Install Google Chat On The Computer", "H2"))
    story.append(
        steps(
            [
                ("Open Google Chrome", "The desktop Chat app is installed through Chrome."),
                ("Go to chat.google.com", "Sign in with the company Google account."),
                ("Click the Install icon", "Use the install icon at the right side of Chrome's address bar."),
                ("If the icon is not visible", "Open Chrome's menu and choose Install Google Chat."),
                ("Open Chat later", "On Windows, open Start and choose Chat. On a Mac, open it from Applications."),
            ]
        )
    )
    story.append(Spacer(1, 8))
    story.append(p("Send A Drive File In Google Chat", "H2"))
    story.extend(
        bullet_items(
            [
                "In Drive, open the correct project and locate the file or folder.",
                "Use Copy link or paste the Drive link into Chat. Do not change sharing permissions unless authorized.",
                "Include the SSD job number, project name, and a short description so the recipient knows exactly what the link is.",
            ]
        )
    )
    story.append(p("Troubleshooting", "H2"))
    story.append(
        data_table(
            ["Problem", "What to do"],
            [
                ["Shared drive is missing", "Check the profile picture and switch to the company Google account. If it is still missing, access must be granted by the Drive administrator."],
                ["Project is hard to find", "Search the full SSD job number first. Then confirm the project name or address."],
                ["DWG will not open in Drive", "Download it and open the local copy in AutoCAD or the approved CAD program."],
                ["No Download option", "You may not have download permission. Ask a supervisor or Drive administrator."],
                ["Chat install icon is missing", "Make sure Chat is open in Chrome and you are signed in. Use Chrome menu > Install Google Chat."],
            ],
            [2.35 * inch, CONTENT_W - 2.35 * inch],
        )
    )
    story.append(Spacer(1, 8))
    story.append(
        callout(
            "Final reminder",
            "Use the correct company account, confirm the SSD job number, and download copies instead of moving shared files.<br/>Never rename, move, replace, or delete a shared folder unless a supervisor tells you to do so.",
            border=RED,
            fill=SOFT_RED,
        )
    )
    story.append(Spacer(1, 6))
    story.append(
        p(
            f"Official help checked July 22, 2026: {link('Drive for desktop help', DRIVE_HELP_URL)} and {link('Google Chat install help', CHAT_INSTALL_URL)}.",
            "Small",
        )
    )
    return story


def build_pdf() -> Path:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=MARGIN_X,
        rightMargin=MARGIN_X,
        topMargin=MARGIN_TOP,
        bottomMargin=MARGIN_BOTTOM,
        title="Dick's CERTASURV Drive and Google Chat Guide",
        subject="How to use the CERTASURV_PROJECT DRIVE and Google Chat",
        author="CERTASURV",
        creator="Codex / ReportLab",
    )
    frame = Frame(
        doc.leftMargin,
        doc.bottomMargin,
        doc.width,
        doc.height,
        leftPadding=0,
        rightPadding=0,
        topPadding=0,
        bottomPadding=0,
    )
    doc.addPageTemplates([PageTemplate(id="guide", frames=[frame], onPage=top_rule)])
    doc.build(build_story())
    return OUT


if __name__ == "__main__":
    output = build_pdf()
    print(output)
