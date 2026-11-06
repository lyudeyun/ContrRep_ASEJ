function s = fmtFixed(x, d)
% FMTFIXED x with d decimals, rounding halves away from zero.
% sprintf rounds the binary value, so a mean of exactly 98.55, stored as
% 98.5499999..., would be printed as 98.5; the small offset restores the
% rounding of the decimal value without affecting any other value.
r = sign(x) .* round(abs(x) * 10^d + 1e-9) / 10^d;
s = sprintf(['%.' num2str(d) 'f'], r);
end
