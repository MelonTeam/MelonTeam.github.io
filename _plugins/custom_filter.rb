module CustomFilter
    def first_image(input)
        # m = /\!\[[^\]]*\]\(([^\)]+\))/.match(input)
        m = /<img\s+src\s*=('|")([^'"]+)\1.*?\/?>/i.match(input)
        if m != nil
            return m[2]
        else
            return nil
        end
    end

    def preview_image(img_url)
        return "<div class='preview-image'><img src='#{img_url}' alt='' /></div>"
    end

    def trim_newlines(input)
        return input.gsub(/(\s)+/,'\1').gsub(/^\s+/, '')
    end

    def strip_htmltags(input)
        return input.gsub(/<\/?[^>]*>/, "")
    end
end

Liquid::Template.register_filter(CustomFilter)