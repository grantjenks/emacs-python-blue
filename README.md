# Emacs Python Blue

Use the Python [Blue](https://pypi.org/project/blue/) package to reformat
Python buffers.


## Usage

The whole buffer can be reformatted with `M-x python-blue-buffer`.

To format every time you save, enable `python-blue-mode` in relevant buffers.

```elisp
(add-hook 'python-mode-hook 'python-blue-mode)
```

Note that if `python-blue-only-if-project-is-blued` is true (the default), then
blue will only run if the project is configured to run blue. Projects can
configure blue through any of a `pyproject.toml`, `setup.cfg`, `tox.ini`, or
`.blue` file.


## Customization

The following variables are available:

- `python-blue-executable` (default "blue") Name of the executable to run.
- `python-blue-only-if-project-is-blued` (default t) Only run blue if project
  has blue configured.

Blue parameters like `--line-length` or `--skip-string-normalization` should be
configured in a `.blue`, `pyproject.toml`, `setup.cfg`, or `tox.ini` file.


## License

MIT License

Copyright (c) 2022 Grant Jenks

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
