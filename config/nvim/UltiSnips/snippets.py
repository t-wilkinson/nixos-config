def upper_right(inp):
    return (64 - len(inp)) * ' ' + inp.upper()

def get_option(snip, option, default=None):
    return snip.opt('g:ultisnips_javascript["{}"]'.format(option), default)
