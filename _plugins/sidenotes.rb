# frozen_string_literal: true

module Jekyll
  module Sidenotes
    # Transforms kramdown footnotes into Tufte-CSS style sidenotes
    #
    # This hook runs after kramdown renders HTML and replaces:
    # - Footnote references: <sup id="fnref:X"><a>...</a></sup>
    # - With Tufte sidenotes: <label><input><span class="sidenote">...</span>
    #
    # The footnote definitions section is completely removed.
    class Converter
      class << self
        def process(content)
          # Extract all footnote definitions into a hash
          footnotes = extract_footnotes(content)

          # Return early if no footnotes found
          return content if footnotes.empty?

          # Replace all footnote references with sidenotes
          content = replace_footnote_references(content, footnotes)

          # Remove the footnotes section
          content = remove_footnotes_section(content)

          content
        end

        private

        # Extracts footnote definitions from the kramdown-generated footnotes div
        # Returns a hash mapping footnote IDs to their content
        def extract_footnotes(content)
          footnotes = {}

          # Find all footnote list items
          # Pattern: <li id="fn:FOOTNOTE_ID">...content...</li>
          content.scan(/<li id="fn:([^"]+)">(.*?)<\/li>/m) do |footnote_id, footnote_content|
            # Remove the back-reference link
            # Pattern: <a href="#fnref:X" class="reversefootnote"...>...</a>
            cleaned_content = footnote_content.gsub(/<a[^>]*class="reversefootnote"[^>]*>.*?<\/a>/m, '')

            # Clean up whitespace and wrapping <p> tags if present
            cleaned_content = cleaned_content.strip

            # If the content is wrapped in a single <p> tag, unwrap it
            if cleaned_content =~ /\A<p>(.*)<\/p>\z/m
              cleaned_content = $1.strip
            end

            footnotes[footnote_id] = cleaned_content
          end

          footnotes
        end

        # Replaces all footnote references with Tufte-style sidenotes
        def replace_footnote_references(content, footnotes)
          # Pattern: <sup id="fnref:FOOTNOTE_ID"><a href="#fn:FOOTNOTE_ID"...>N</a></sup>
          content.gsub(/<sup id="fnref:([^"]+)"[^>]*>.*?<\/sup>/m) do |match|
            footnote_id = $1
            footnote_content = footnotes[footnote_id]

            # If we don't have content for this footnote, leave it unchanged
            next match unless footnote_content

            # Generate a unique sidenote ID
            sidenote_id = "sn-#{footnote_id}"

            # Create the Tufte-style sidenote HTML
            create_sidenote(sidenote_id, footnote_content)
          end
        end

        # Creates the Tufte-style sidenote HTML structure
        def create_sidenote(sidenote_id, content)
          %(<label for="#{sidenote_id}" class="margin-toggle sidenote-number"></label><input type="checkbox" id="#{sidenote_id}" class="margin-toggle"/><span class="sidenote">#{content}</span>)
        end

        # Removes the footnotes section from the document
        def remove_footnotes_section(content)
          # Remove the entire footnotes div
          # Pattern: <div class="footnotes"...>...</div>
          # This needs to match the full div including nested content
          content.gsub(/<div class="footnotes"[^>]*>.*?<\/div>/m, '')
        end
      end
    end
  end
end

# Register the Jekyll hook to run after rendering
Jekyll::Hooks.register :documents, :post_render do |doc|
  # Only process HTML files (posts, pages, etc.)
  if doc.output_ext == '.html'
    doc.output = Jekyll::Sidenotes::Converter.process(doc.output)
  end
end

# Also handle pages
Jekyll::Hooks.register :pages, :post_render do |page|
  # Only process HTML files
  if page.output_ext == '.html'
    page.output = Jekyll::Sidenotes::Converter.process(page.output)
  end
end
