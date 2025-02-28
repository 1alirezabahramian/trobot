from telegram import Update
from telegram.ext import Application, CommandHandler, CallbackContext
import requests

TOKEN = '8015756624:AAHK0mGjLMdICEIZZlutv53nlAHG6O9EN4I'
CHANNEL_USERNAME = "@sekehmarkazi"  # شناسه کانال

async def start(update: Update, context: CallbackContext):
    # دریافت کد محصول از لینک
    product_code = context.args[0] if context.args else None
    if not product_code:
        await update.message.reply_text("⚠️ لینک اشتباه است! لطفاً لینک صحیح را وارد کنید.")
        return

    # بررسی طول کد محصول
    if len(product_code) not in [15, 16]:
        await update.message.reply_text("⚠️ کد محصول باید 15 یا 16 رقم باشد!")
        return

    # بررسی عضویت کاربر در کانال
    user_id = update.message.from_user.id
    member = await update.message.chat.get_member(user_id)
    if member.status not in ['member', 'administrator']:
        await update.message.reply_text(
            "برای دریافت قیمت، لطفاً به کانال ما بپیوندید:\n"
            f"{CHANNEL_USERNAME}\n\nپس از عضویت، دوباره تلاش کنید."
        )
        return

    # تجزیه کد محصول
    try:
        weight = float(product_code[:2] + '.' + product_code[2:5])  # وزن
        purity = int(product_code[5:8])  # عیار
        charge_type = int(product_code[8])  # نوع اجرت
        charge_value = int(product_code[9:11])  # مقدار اجرت
        charge_exponent = int(product_code[11]) if len(product_code) == 16 else 0  # توان اجرت (برای کد 16 رقمی)
        product_id = product_code[12:]  # شناسه محصول
    except ValueError as e:
        await update.message.reply_text(f"⚠️ خطا در پردازش کد محصول: {e}")
        return

    # دریافت قیمت لحظه‌ای طلای 18 عیار از API
    response = requests.get("http://app.talaclinicfars.com:80/api/prices.php?r=java.util.Random@4916e7f&token=EdT6OZMDoLp9qcHytbeaBSUQAh4gJ58NYzxlsjCnm0")
    gold_prices = response.json()

    gold_18_price = None
    for item in gold_prices:
        if item["name"] == "geram18_in_shiraz":
            gold_18_price = int(item["price"].replace(",", ""))
            break

    if gold_18_price is None:
        await update.message.reply_text("❌ خطا در دریافت قیمت طلا!")
        return

    # محاسبه قیمت نهایی
    weight_750 = (weight * purity) / 750  # وزن معادل 750
    base_price = weight_750 * gold_18_price  # قیمت پایه
    if charge_type == 1:
        charge_amount = (base_price * charge_value) / 100  # اجرت درصدی
    else:
        charge_amount = charge_value * (10 ** charge_exponent)  # اجرت ثابت

    final_price = base_price + charge_amount  # قیمت نهایی

    # رند کردن قیمت به 3 رقم آخر
    final_price_rounded = round(final_price, -3)

    # نمایش قیمت نهایی
    await update.message.reply_text(
        f"کد محصول: {product_code[-4:]}\n"
        f"✅ قیمت نهایی: {final_price_rounded:,.0f} تومان"
    )

def main():
    app = Application.builder().token(TOKEN).build()

    app.add_handler(CommandHandler("start", start))

    print("✅ ربات در حال اجرا است...")
    app.run_polling()

if __name__ == "__main__":
    main()
