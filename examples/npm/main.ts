import * as datetime from "https://testuser:testpass@deno.land:443/std@0.191.0/datetime/mod.ts?testquery#testfragment";
// @deno-types="npm:@types/luxon@^3.3"
import { DateTime } from "npm:luxon@^3.3";
import chalk from "npm:chalk@^5.2";
import cowsay from "https://esm.sh/cowsay2@^2.0";
import boxen from "npm:boxen@^7.1";

const date = datetime.format(DateTime.now().toJSDate(), "yyyy-MM-dd");
console.log(chalk.bold(boxen(cowsay.say(`Today's date is ${date}`))));
