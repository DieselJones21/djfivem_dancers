-- Standalone check for wash split math (run with: lua tests/test_wash.lua)
dofile('shared/utils.lua')

local failed = 0

local function expect(name, gotClean, gotFee, wantClean, wantFee)
    if gotClean ~= wantClean or gotFee ~= wantFee then
        failed = failed + 1
        print(('FAIL %s: clean=%s fee=%s (wanted clean=%s fee=%s)'):format(name, gotClean, gotFee, wantClean, wantFee))
    else
        print(('PASS %s: clean=%s fee=%s'):format(name, gotClean, gotFee))
    end
end

local c, f = DJF.WashSplit(1000, 17.5)
expect('1000 @ 17.5%', c, f, 825, 175)

c, f = DJF.WashSplit(10000, 17.5)
expect('10000 @ 17.5%', c, f, 8250, 1750)

c, f = DJF.WashSplit(1, 17.5)
expect('1 @ 17.5% floors fee to 0', c, f, 1, 0)

c, f = DJF.WashSplit(0, 17.5)
expect('zero amount', c, f, 0, 0)

c, f = DJF.WashSplit(-50, 17.5)
expect('negative amount', c, f, 0, 0)

c, f = DJF.WashSplit(200, 100)
expect('100 percent fee', c, f, 0, 200)

c, f = DJF.WashSplit(200, 0)
expect('0 percent fee', c, f, 200, 0)

print(DJF.FormatMoney(8250) == '$8,250' and 'PASS format 8250' or 'FAIL format 8250')
if DJF.FormatMoney(8250) ~= '$8,250' then failed = failed + 1 end

print(DJF.FormatMoney(175) == '$175' and 'PASS format 175' or 'FAIL format 175')
if DJF.FormatMoney(175) ~= '$175' then failed = failed + 1 end

if failed > 0 then
    print(failed .. ' test(s) failed')
    os.exit(1)
end

print('All wash tests passed')
