require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "render_markdown renders markdown as safe html in a prose container" do
    html = render_markdown("See **bold** and a [link](https://example.com).")

    assert_dom_equal <<~HTML, html
      <div class="prose prose-invert prose-zinc max-w-none">
        <p>See <strong>bold</strong> and a <a href="https://example.com">link</a>.</p>
      </div>
    HTML
  end

  test "render_markdown highlights fenced code blocks" do
    html = render_markdown("```ruby\nputs 1\n```")

    assert_includes html, '<pre lang="ruby"'
    assert_includes html, "<code>"
    assert_includes html, 'style="color:'
  end

  test "render_markdown returns empty string for blank input" do
    assert_equal "", render_markdown(nil)
    assert_equal "", render_markdown("   ")
  end
end