#!/usr/bin/env python3
"""Bulk-generate translation pairs via Gemini and output as JSON for --pairs-dir.

Usage:
    python tool/generate_ai_pairs.py [--api-key KEY] [--langs ur,fa] [--batch-size 25]

You can provide the API key via:
    1. --api-key argument
    2. GEMINI_API_KEY environment variable
    3. A .env file in the tool/ directory (GEMINI_API_KEY=your-key)

Outputs JSON files in the format expected by build_expanded_dictionary.dart --pairs-dir.
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None

from google import genai

# ---------------------------------------------------------------------------
# High-frequency word lists (500+ each)
# ---------------------------------------------------------------------------

URDU_WORDS = [
    # Pronouns & basic
    "میں", "تم", "آپ", "وہ", "یہ", "ہم", "ان", "اس", "کون", "کیا",
    "میرا", "تمہارا", "آپ کا", "اس کا", "ان کا", "ہمارا",
    # Greetings & politeness
    "السلام علیکم", "خدا حافظ", "شکریہ", "مہربانی", "معاف کیجیے",
    "برائے مہربانی", "جی ہاں", "نہیں", "جی", "تعریف",
    # Numbers 1-20
    "ایک", "دو", "تین", "چار", "پانچ", "چھ", "سات", "آٹھ", "نو", "دس",
    "گیارہ", "بارہ", "تیرہ", "چودہ", "پندرہ", "سولہ", "سترہ", "اٹھارہ", "انیس", "بیس",
    # Time
    "آج", "کل", "اب", "بعد", "پہلے", "صبح", "شام", "رات", "دن", "ہفتہ",
    "مہینہ", "سال", "گھنٹہ", "منٹ", "دیر", "جلدی", "ہمیشہ", "کبھی", "ابھی", "پھر",
    # Question words
    "کیوں", "کیسے", "کتنا", "کب", "کہاں", "کس", "کون سا",
    # Common verbs
    "ہونا", "کرنا", "جانا", "آنا", "دینا", "لینا", "کہنا", "دیکھنا", "سننا", "آنا",
    "رہنا", "پڑھنا", "لکھنا", "سمجھنا", "کھانا", "پینا", "سونا", "جاگنا", "بیٹھنا", "کھڑا ہونا",
    "چلنا", "دوڑنا", "بولنا", "پوچھنا", "بتانا", "لانا", "بھیجنا", "ملنا", "روکنا", "کھولنا",
    "بند کرنا", "رکھنا", "نکلنا", "گھومنا", "اٹھنا", "گرنا", "مارنا", "پکڑنا", "چھوڑنا", "لگنا",
    # Common nouns - food
    "پانی", "روٹی", "چاول", "دودھ", "چائے", "قہوہ", "شکر", "نمک", "گوشت", "سبزی",
    "پھل", "انڈہ", "مکھن", "تلی", "مرچ", "دہی", "بریانی", "کری", "روٹی", "نمکین",
    # Common nouns - body
    "سر", "آنکھ", "کان", "ناک", "منہ", "ہاتھ", "پاؤں", "دل", "جگر", "ہڈی",
    "خون", "جلد", "بال", "دانتوں", "زبان", "ہونٹ", "گردن", "پیٹھ", "پیٹ", "انگلی",
    # Common nouns - nature
    "آسمان", "زمین", "پانی", "آگ", "ہوا", "پہاڑ", "سمندر", "دریا", "جنگل", "درخت",
    "پتہ", "پھول", "ستارہ", "چاند", "سورج", "بارش", "برف", "بادل", "اندھیرا", "روشنی",
    # Common nouns - home & objects
    "گھر", "کمرہ", "دروازہ", "کھڑکی", "میز", "کرسی", "بستر", "کتاب", "قلم", "کاغذ",
    "چابی", "بجلی", "پنکھا", "صابن", "تکیہ", "کمبل", "برتن", "چمچ", "کانٹا", "چھری",
    # Common nouns - society
    "شہر", "گاؤں", "ملک", "سڑک", "پل", "مدرسہ", "یونیورسٹی", "اسپتال", "مسجد", "دکان",
    "بازار", "دفتر", "کارخانہ", "عدالت", "جیل", "فوج", "پولیس", "حکومت", "قانون",
    # Family
    "ماں", "باپ", "بھائی", "بہن", "بیٹا", "بیٹی", "دادی", "دادا", "نانی", "نانا",
    "چچا", "تایا", "خالہ", "پھوپھی", "بھانجا", "بھتیجا", "کزن", "شوہر", "بیوی", "رشتہ دار",
    # Adjectives
    "اچھا", "برا", "بڑا", "چھوٹا", "نیا", "پرانا", "لمبا", "چھوٹا", "مہنگا", "سستا",
    "صاف", "گندا", "گرم", "سرد", "نرم", "سخت", "تیز", "آہستہ", "اونچا", "نیچے",
    "قریب", "دور", "بھاری", "ہلکا", "خالی", "بھرا", "کھلا", "بند", "مشکل", "آسان",
    "خوبصورت", "بدصورت", "امیر", "غریب", "بہادر", "ڈرپوک", "سچا", "جھوٹا", "مہربان", "ظالم",
    "خوش", "اداس", "تھکا", "بیمار", "صحت مند", "پاگل", "دانا", "بیوقوف", "شرمندہ", "فخر",
    # Adpositions & connectors
    "میں", "پر", "سے", "کے لیے", "کے ساتھ", "بغیر", "تک", "اندھر", "باہر", "اوپر",
    "نیچے", "آگے", "پیچھے", "دائیں", "بائیں", "درمیان", "پاس", "برخلاف", "مگر", "لیکن",
    "کیونکہ", "اگر", "تو", "جب", "جب تک", "جب کہ", "چونکہ", "حالانکہ", "تاہم", "ورنہ",
    # Occupations
    "ڈاکٹر", "انجینئر", "استاد", "وکیل", "تاجر", "کسان", "مزدور", "پولیس والا", "فوجی", "پائلٹ",
    "ملاح", "باورچی", "ڈرائیور", "نائب", "صدر", "وزیر", "منیجر", "ملازم", "چھوکرا", "مالک",
    # Abstract
    "محبت", "نفرت", "خوشی", "غم", "امید", "مایوسی", "ایمان", "یقین", "شک", "صلح",
    "جنگ", "امن", "انصاف", "ظلم", "آزادی", "غلامی", "سچ", "جھوٹ", "دوستی", "دشمنی",
    # Education
    "علم", "تعلیم", "سبق", "امتحان", "درجہ", "جماعت", "مضمون", "ریاضی", "سائنس", "تاریخ",
    "جغرافیہ", "انگریزی", "عربی", "فارسی", "شاعری", "ادب", "قاعدہ", "قانون",
    "صفحہ", "باب", "نمبر", "جواب", "سوال", "مشق",
    # Colors
    "سرخ", "نیلا", "سبز", "پیلا", "سفید", "سیاہ", "بھورا", "نارنجی", "جامنی", "گلابی",
    # Directions
    "شمال", "جنوب", "مشرق", "مغرب", "اوپر", "نیچے", "دائیں", "بائیں", "سیدھا", "مڑنا",
    # Miscellaneous
    "بات", "کام", "نام", "شکل", "بات چیت", "خبر", "قسم", "طرح", "طرح کا", "طرح پر",
    "شروع", "ختم", "باقی", "کل", "سب", "بہت", "تھوڑا", "کچھ", "کوئی", "ہر",
]

FARSI_WORDS = [
    # Pronouns & basic
    "من", "تو", "شما", "او", "این", "آن", "ما", "ایشان", "چه", "کدام",
    "مال من", "مال تو", "مال شما", "مال او", "مال آنها", "مال ما",
    # Greetings & politeness
    "سلام", "خداحافظ", "متشکرم", "مرسی", "ببخشید", "خواهش می‌کنم",
    "لطفاً", "بله", "نه", "بفرمایید", "معذرت می‌خواهم", "خوش آمدید",
    # Numbers 1-20
    "یک", "دو", "سه", "چهار", "پنج", "شش", "هفت", "هشت", "نه", "ده",
    "یازده", "دوازده", "سیزده", "چهارده", "پانزده", "شانزده", "هفده", "هجده", "نوزده", "بیست",
    # Time
    "امروز", "دیروز", "فردا", "اکنون", "بعد", "قبل", "صبح", "عصر", "شب", "روز",
    "هفته", "ماه", "سال", "ساعت", "دقیقه", "دیر", "زود", "همیشه", "گاهی", "دوباره",
    # Question words
    "چرا", "چطور", "چقدر", "کی", "کجا", "کدام", "چی",
    # Common verbs
    "بودن", "کردن", "رفتن", "آمدن", "دادن", "گرفتن", "گفتن", "دیدن", "شنیدن", "دانستن",
    "خواستن", "توانستن", "بایستن", "خواندن", "نوشتن", "فهمیدن", "خوردن", "آشامیدن", "خوابیدن", "ایستادن",
    "نشستن", "دویدن", "راه رفتن", "پرسیدن", "گفتن", "آوردن", "فرستادن", "ملاقات کردن", "بستن", "باز کردن",
    "نگه داشتن", "درآوردن", "گشتن", "برخاستن", "افتادن", "زدن", "گرفتن", "رها کردن", "رسیدن", "ماندن",
    # Common nouns - food
    "آب", "نان", "برنج", "شیر", "چای", "قهوه", "شکر", "نمک", "گوشت", "سبزی",
    "میوه", "تخم مرغ", "کره", "روغن", "فلفل", "ماست", "آش", "خورشت", "کباب", "پنیر",
    # Common nouns - body
    "سر", "چشم", "گوش", "بینی", "دهان", "دست", "پا", "قلب", "کبد", "استخوان",
    "خون", "پوست", "مو", "دندان", "زبان", "لب", "گردن", "پشت", "شکم", "انگشت",
    # Common nouns - nature
    "آسمان", "زمین", "آب", "آتش", "باد", "کوه", "دریا", "رودخانه", "جنگل", "درخت",
    "برگ", "گل", "ستاره", "ماه", "خورشید", "باران", "برف", "ابر", "تاریکی", "نور",
    # Common nouns - home & objects
    "خانه", "اتاق", "در", "پنجره", "میز", "صندلی", "تخت", "کتاب", "قلم", "کاغذ",
    "کلید", "برق", "پنکه", "صابون", "بالش", "پتو", "ظرف", "قاشق", "چنگال", "چاقو",
    # Common nouns - society
    "شهر", "روستا", "کشور", "خیابان", "پل", "مدرسه", "دانشگاه", "بیمارستان", "مسجد", "فروشگاه",
    "بازار", "اداره", "کارخانه", "دادگاه", "زندان", "ارتش", "پلیس", "دولت", "قانون",
    # Family
    "مادر", "پدر", "برادر", "خواهر", "پسر", "دختر", "مادر بزرگ", "پدر بزرگ", "مادربزرگ", "پدربزرگ",
    "عمو", "دایی", "عمه", "خاله", "خواهرزاده", "برادرزاده", "پسرعمو", "شوهر", "زن", "فامیل",
    # Adjectives
    "خوب", "بد", "بزرگ", "کوچک", "نو", "قدیمی", "بلند", "کوتاه", "گران", "ارزان",
    "تمیز", "کثیف", "گرم", "سرد", "نرم", "سخت", "تیز", "آهسته", "بلند", "پایین",
    "نزدیک", "دور", "سنگین", "سبک", "خالی", "پر", "باز", "بسته", "مشکل", "آسان",
    "زیبا", "زشت", "ثروتمند", "فقیر", "شجاع", "ترسو", "راستگو", "دروغگو", "مهربان", "ظالم",
    "خوشحال", "غمگین", "خسته", "مریض", "سالم", "دیوانه", "عاقل", "احمق", "شرمنده", "مفتخر",
    # Adpositions & connectors
    "در", "روی", "از", "برای", "با", "بدون", "تا", "داخل", "بیرون", "بالا",
    "پایین", "جلو", "عقب", "راست", "چپ", "بین", "کنار", "برعکس", "اما", "ولی",
    "زیرا", "اگر", "پس", "وقتی", "تا وقتی", "در حالی که", "چون", "اگرچه", "با این حال", "در غیر این صورت",
    # Occupations
    "دکتر", "مهندس", "معلم", "وکیل", "تاجر", "کشاورز", "کارگر", "پلیس", "سرباز", "خلبان",
    "ملوان", "آشپز", "راننده", "معاون", "رئیس", "وزیر", "مدیر", "کارمند", "خدمتکار", "صاحب",
    # Abstract
    "عشق", "نفرت", "شادی", "غم", "امید", "ناامیدی", "ایمان", "اطمینان", "شک", "صلح",
    "جنگ", "آرامش", "عدالت", "ستم", "آزادی", "بردگی", "راستی", "دروغ", "دوستی", "دشمنی",
    # Education
    "علم", "آموزش", "درس", "امتحان", "مدرک", "کلاس", "موضوع", "ریاضی", "علوم", "تاریخ",
    "جغرافیا", "انگلیسی", "عربی", "فارسی", "شعر", "ادبیات", "قانون", "صفحه", "فصل", "شماره",
    "جواب", "سوال", "تمرین",
    # Colors
    "قرمز", "آبی", "سبز", "زرد", "سفید", "سیاه", "قهوه‌ای", "نارنجی", "بنفش", "صورتی",
    # Directions
    "شمال", "جنوب", "شرق", "غرب", "بالا", "پایین", "راست", "چپ", "مستقیم", "پیچیدن",
    # Miscellaneous
    "حرف", "کار", "اسم", "شکل", "گفتگو", "خبر", "نوع", "جور", "ابتداء", "پایان",
    "باقی", "دیروز", "همه", "خیلی", "کمی", "چیزی", "کسی", "هر",
]

# ---------------------------------------------------------------------------
# Batch prompt
# ---------------------------------------------------------------------------

BATCH_PROMPT_TPL = """You are a bilingual dictionary generator. For each word in the list below, provide translations from {source} to {target}. Return ONLY valid JSON — NO markdown, NO commentary.

The JSON must be a flat object {{"word1": ["translation1", "translation2"], "word2": ["translation1"], ...}}.

Rules:
- Give 1-3 common, accurate translations per word.
- If a word has multiple senses, include the most frequent ones.
- Use standard modern {target} script (Arabic/Perso-Arabic).
- If a word is a verb, give the infinitive form in {target}.
- If no good translation exists, give the closest approximation.

Words to translate:
{words}
"""


def main():
    parser = argparse.ArgumentParser(description="Generate AI translation pairs")
    parser.add_argument("--api-key", help="Gemini API key (or set GEMINI_API_KEY env var)")
    parser.add_argument("--langs", default="ur,fa", help="Comma-separated target languages (ur, fa)")
    parser.add_argument("--batch-size", type=int, default=30, help="Words per API call")
    parser.add_argument("--rate-limit", type=float, default=4.0, help="Seconds between API calls")
    parser.add_argument("--output-dir", default="third_party/ai_pairs", help="Output directory for JSON files")
    parser.add_argument("--model", default="gemini-2.0-flash", help="Gemini model name")
    args = parser.parse_args()

    api_key = args.api_key or os.environ.get("GEMINI_API_KEY")
    # Load .env file from script directory as fallback
    if not api_key and load_dotenv is not None:
        env_path = Path(__file__).parent / ".env"
        if env_path.exists():
            load_dotenv(env_path)
            api_key = os.environ.get("GEMINI_API_KEY")

    if not api_key:
        print("ERROR: Provide --api-key or set GEMINI_API_KEY env var", file=sys.stderr)
        sys.exit(1)

    langs = [lang.strip() for lang in args.langs.split(",")]
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    word_lists = {}
    if "ur" in langs:
        word_lists["ur"] = URDU_WORDS
    if "fa" in langs:
        word_lists["fa"] = FARSI_WORDS
    # Also generate reverse pairs from English common words
    english_basic = [
        "hello", "goodbye", "thank", "please", "sorry", "yes", "no", "water", "bread", "time",
        "day", "night", "week", "month", "year", "today", "tomorrow", "yesterday", "now", "later",
        "person", "man", "woman", "child", "people", "friend", "family", "father", "mother", "brother",
        "sister", "son", "daughter", "husband", "wife", "home", "house", "door", "room", "bed",
        "table", "chair", "book", "pen", "paper", "food", "eat", "drink", "cook", "water",
        "milk", "bread", "rice", "meat", "fruit", "salt", "sugar", "oil", "egg", "butter",
        "head", "eye", "ear", "nose", "mouth", "hand", "foot", "heart", "blood", "bone",
        "big", "small", "hot", "cold", "new", "old", "good", "bad", "beautiful", "ugly",
        "rich", "poor", "happy", "sad", "tired", "sick", "healthy", "strong", "weak", "fast",
        "slow", "hard", "soft", "heavy", "light", "clean", "dirty", "open", "closed", "empty",
        "full", "high", "low", "near", "far", "long", "short", "cheap", "expensive", "easy",
        "difficult", "possible", "necessary", "real", "false", "true", "same", "different",
        "love", "hate", "work", "money", "school", "university", "teacher", "student", "doctor",
        "engineer", "police", "soldier", "government", "city", "country", "street", "market",
        "shop", "office", "hospital", "mosque", "park", "garden", "tree", "flower", "sky",
        "sun", "moon", "star", "rain", "snow", "wind", "fire", "sea", "river", "mountain",
        "road", "bridge", "car", "bus", "train", "airport", "station", "journey", "travel",
        "life", "death", "health", "illness", "medicine", "hope", "fear", "anger", "peace",
        "war", "freedom", "justice", "truth", "lie", "knowledge", "power", "language",
        "write", "read", "speak", "listen", "walk", "run", "sit", "stand", "sleep", "wake",
        "come", "go", "give", "take", "buy", "sell", "find", "lose", "keep", "start",
        "finish", "help", "ask", "answer", "think", "believe", "know", "understand",
        "learn", "teach", "remember", "forget", "bring", "send", "show", "tell", "try",
        "change", "make", "build", "grow", "cut", "break", "fix", "wash", "clean",
        "red", "blue", "green", "yellow", "white", "black", "brown", "orange", "purple", "pink",
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "hundred", "thousand", "first", "last", "next", "previous", "many", "few", "some", "all",
        "every", "each", "other", "another", "this", "that", "these", "those", "here", "there",
        "where", "when", "why", "how", "what", "which", "who", "whom", "whose",
    ]

    client = genai.Client(api_key=api_key)

    def generate_batch(words, source_lang, target_lang):
        """Send a batch of words to Gemini and parse the response."""
        word_list = "\n".join(f"- {w}" for w in words)
        prompt = BATCH_PROMPT_TPL.format(
            source=source_lang, target=target_lang, words=word_list
        )
        try:
            response = client.models.generate_content(
                model=args.model,
                contents=prompt,
                config={
                    "response_mime_type": "application/json",
                },
            )
            text = response.text.strip()
            # Strip markdown code fences if present
            if text.startswith("```"):
                text = text.split("\n", 1)[1]
                text = text.rsplit("```", 1)[0].strip()
            result = json.loads(text)
            # Validate structure
            if not isinstance(result, dict):
                print(f"  WARNING: response is not a dict, got {type(result).__name__}")
                return {}
            return result
        except Exception as e:
            print(f"  ERROR: {e}")
            return {}

    def save_pairs(pairs, filename):
        """Save pairs JSON and return count."""
        path = out_dir / filename
        with open(path, "w", encoding="utf-8") as f:
            json.dump(pairs, f, ensure_ascii=False, indent=2)
        count = sum(len(v) for v in pairs.values())
        entry_count = len(pairs)
        print(f"  Wrote {entry_count} entries ({count} translations) -> {path}")
        return entry_count

    # --- Generate language pairs ---

    # EN → UR, EN → FA
    for target_lang in langs:
        pair_id = f"en_{target_lang}"
        reverse_id = f"{target_lang}_en"
        print(f"\n{'='*60}")
        print(f"Generating {pair_id} ...")
        print(f"{'='*60}")

        all_pairs = {}
        batches = [
            english_basic[i:i + args.batch_size]
            for i in range(0, len(english_basic), args.batch_size)
        ]
        total = len(batches)
        for idx, batch in enumerate(batches):
            print(f"  Batch {idx+1}/{total} ({len(batch)} words) ...", end=" ", flush=True)
            result = generate_batch(batch, "English", target_lang.upper())
            all_pairs.update(result)
            if idx < total - 1:
                time.sleep(args.rate_limit)
            print(f"done ({len(result)} words)")

        # Remove entries with empty translation lists
        all_pairs = {k: v for k, v in all_pairs.items() if v}
        save_pairs(all_pairs, f"{pair_id}.json")

        # Build reverse: {target_word: [source_words]}
        reverse_pairs = {}
        for en_word, translations in all_pairs.items():
            for t in translations:
                norm = t.strip()
                if norm:
                    reverse_pairs.setdefault(norm, []).append(en_word)
        # Deduplicate
        reverse_pairs = {k: list(set(v)) for k, v in reverse_pairs.items()}
        save_pairs(reverse_pairs, f"{reverse_id}.json")

    # --- Generate UR → FA, FA → UR (cross pairs) ---
    if "ur" in langs and "fa" in langs:
        print(f"\n{'='*60}")
        print(f"Generating ur_fa and fa_ur cross pairs ...")
        print(f"{'='*60}")
        for source_lang, target_lang, pair_id in [
            ("Urdu", "Farsi", "ur_fa"),
            ("Farsi", "Urdu", "fa_ur"),
        ]:
            source_words = word_lists[source_lang[:2].lower()]
            batches = [
                source_words[i:i + args.batch_size]
                for i in range(0, len(source_words), args.batch_size)
            ]
            all_pairs = {}
            total = len(batches)
            for idx, batch in enumerate(batches):
                print(f"  Batch {idx+1}/{total} ({len(batch)} words) ...", end=" ", flush=True)
                result = generate_batch(batch, source_lang, target_lang)
                all_pairs.update(result)
                if idx < total - 1:
                    time.sleep(args.rate_limit)
                print(f"done ({len(result)} words)")
            all_pairs = {k: v for k, v in all_pairs.items() if v}
            save_pairs(all_pairs, f"{pair_id}.json")

    # --- Generate Hi -> UR, Hi -> FA, UR -> Hi, FA -> Hi ---

    # --- Generate Hi → UR, Hi → FA, UR → Hi, FA → Hi ---
    hindi_words = [
        "नमस्ते", "शुक्रिया", "कृपया", "माफ़ कीजिये", "अलविदा", "हाँ", "नहीं",
        "मैं", "तुम", "आप", "वह", "यह", "हम", "वे", "कौन", "क्या",
        "मेरा", "तुम्हारा", "आपका", "उसका",
        "एक", "दो", "तीन", "चार", "पाँच", "छः", "सात", "आठ", "नौ", "दस",
        "पानी", "रोटी", "दूध", "चावल", "चाय", "दाल", "सब्ज़ी", "फल", "मांस", "नमक",
        "चीनी", "तेल", "मक्खन", "अंडा", "मछली",
        "सिर", "आँख", "कान", "नाक", "मुँह", "हाथ", "पैर", "दिल", "खून", "हड्डी",
        "ज़बान", "बाल", "दाँत",
        "समय", "दिन", "रात", "सुबह", "शाम", "आज", "कल", "अब", "बाद", "पहले",
        "हफ़्ता", "महीना", "साल",
        "बड़ा", "छोटा", "अच्छा", "बुरा", "नया", "पुराना", "गरम", "ठंडा", "मीठा", "खट्टा",
        "लंबा", "कम", "ज़्यादा", "मुश्किल", "आसान", "महँगा", "सस्ता", "साफ़", "गंदा",
        "खुश", "उदास", "थका", "बीमार", "स्वस्थ", "अमीर", "गरीब", "सच", "झूठ",
        "पिता", "माता", "भाई", "बहन", "बेटा", "बेटी", "पति", "पत्नी", "दोस्त",
        "घर", "कमरा", "दरवाज़ा", "खिड़की", "मेज़", "कुर्सी", "बिस्तर", "किताब", "कलम", "काग़ज़",
        "चाबी", "बिजली", "पंखा", "साबुन",
        "शहर", "गाँव", "देश", "सड़क", "पुल", "स्कूल", "मस्जिद", "मंदिर", "बाज़ार", "दुकान",
        "अस्पताल", "कारख़ाना", "सरकार",
        "डॉक्टर", "इंजीनियर", "शिक्षक", "वकील", "व्यापारी", "किसान", "मज़दूर", "पुलिस", "सिपाही",
        "प्रेम", "नफ़रत", "ख़ुशी", "दुख", "आशा", "निराशा", "शांति", "युद्ध", "स्वतंत्रता", "न्याय",
        "ज्ञान", "शक्ति", "भाषा",
        "लाल", "नीला", "हरा", "पीला", "सफ़ेद", "काला", "भूरा", "नारंगी", "बैंगनी", "गुलाबी",
        "आना", "जाना", "करना", "होना", "देना", "लेना", "खाना", "पीना", "देखना", "सुनना",
        "बोलना", "पढ़ना", "लिखना", "समझना", "जानना", "चाहना", "सकना", "रहना", "चलना", "दौड़ना",
        "बैठना", "खड़ा", "सोना", "जागना", "कहना", "पूछना", "बताना", "लाना", "भेजना", "मिलना",
        "उत्तर", "प्रश्न", "नाम", "काम", "बात",
    ]

    for src, tgt, pair_id in [
        ("Hindi", "Urdu", "hi_ur"),
        ("Hindi", "Farsi", "hi_fa"),
        ("Urdu", "Hindi", "ur_hi"),
        ("Farsi", "Hindi", "fa_hi"),
    ]:
        print(f"\n{'='*60}")
        print(f"Generating {pair_id} ...")
        print(f"{'='*60}")
        src_words = hindi_words if src == "Hindi" else word_lists.get(src[:2].lower(), [])
        if not src_words:
            print(f"  Skipping {pair_id}: no word list for {src}")
            continue
        batches = [
            src_words[i:i + args.batch_size]
            for i in range(0, len(src_words), args.batch_size)
        ]
        all_pairs = {}
        total = len(batches)
        for idx, batch in enumerate(batches):
            print(f"  Batch {idx+1}/{total} ({len(batch)} words) ...", end=" ", flush=True)
            result = generate_batch(batch, src, tgt)
            all_pairs.update(result)
            if idx < total - 1:
                time.sleep(args.rate_limit)
            print(f"done ({len(result)} words)")
        all_pairs = {k: v for k, v in all_pairs.items() if v}
        save_pairs(all_pairs, f"{pair_id}.json")

    print(f"\n{'='*60}")
    print(f"Done! All pairs written to {out_dir}")
    print(f"Run the build tool with: dart run tool/build_expanded_dictionary.dart --pairs-dir {out_dir}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
