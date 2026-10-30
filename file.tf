resource "local_file" "myflile" {
    filename = "index.html"
    content = <<-EOT
            <html>
                <head>
                    <title> this is the title</title>
                </head>
                <body>
                    <h1>HTML file </h1>
                </body>
            </html>
            EOT
}