import puppeteer from "puppeteer";

// const email = Bun.env.GITHUB_USERNAME;
// const password = Bun.env.GITHUB_PASSWORD;
// const twoFactorCode = Bun.env.GITHUB_2FA;

const userDataDir = `${process.env.HOME}/.config/raycast/scripts/profile`;

const browser = await puppeteer.launch({
  headless: true,
  userDataDir,
});
const page = await browser.newPage();
page.setDefaultTimeout(10000);

try {
  // await page.goto("https://github.com/settings/copilot/features");

  // // Redirected to login
  // await page.goto("https://github.com/login");

  // await page.type('input[name="login"]', email);
  // await page.type('input[name="password"]', password);
  // await page.click('input[type="submit"]');
  // await page.waitForNavigation();

  // if (page.url().includes("/sessions/two-factor")) {
  //   await page.type('input[name="app_otp"]', twoFactorCode);
  //   await page.click(
  //     'form[action="/sessions/two-factor"] button[type="submit"]',
  //   );
  //   await page.waitForNavigation();
  // }

  await page.goto("https://github.com/settings/copilot/features");

  const usageElement = await page.$(
    "#copilot-overages-usage div div:nth-child(2)",
  );
  if (usageElement) {
    const percentageText = await page.evaluate(
      (el) => el.textContent,
      usageElement,
    );
    if (percentageText) {
      const match = percentageText.match(/(\d+\.\d+)%/);
      if (match) {
        console.log(match[1]);
      } else {
        console.error("Could not extract percentage from:", percentageText);
      }
    } else {
      console.error("Could not find usage percentage element");
    }
  } else {
    console.error("Could not find usage percentage element");
  }
} catch (error) {
  console.error("Error fetching Copilot usage:", error.message);
} finally {
  await browser.close();
}
