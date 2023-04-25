# tabby.nvim

A simple plugin for managing tabs in neovim (see video)


https://user-images.githubusercontent.com/17733465/234137693-2c645fe6-e79c-4799-af8c-e2ef9f3a264d.mp4


To install with `Lazy`:

```
{
    "medwatt/tabby.nvim",
    config = function() require("tabby").setup({sessions_path = "/path/where/sessions/will/be/stored"}) end,
},

```

As of now, because of the way tabs work in vim, using regular `bdelete` doesn't work as expected.
To delete buffers, use the include command `TabulousDeleteBuffer`.
