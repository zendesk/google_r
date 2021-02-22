require 'spec_helper'

describe GoogleR::Contact do
  before do
    single_contact_path = "spec/fixtures/single_contact.xml"
    doc = Nokogiri::XML.parse(File.read(single_contact_path))
    doc.remove_namespaces!
    @doc_root = doc.root
  end

  let(:contact) { GoogleR::Contact.from_xml(@doc_root) }
  subject { contact }

  context "should load id and etag from xml" do
    describe '#google_id' do
      subject { super().google_id }
      it { is_expected.to eq("http://www.google.com/m8/feeds/contacts/michal%40futuresimple.com/base/2f30e7d8bf01953") }
    end

    describe '#etag' do
      subject { super().etag }
      it { is_expected.to eq("\"Q3o6cDVSLit7I2A9WhVSGEkOQgI.\"") }
    end
  end

  context "should load emails from xml" do
    let (:emails) { GoogleR::Contact.from_xml(@doc_root).emails }
    subject { emails }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(4) }
    end

    context "home_email" do
      subject { emails.find { |e| e.rel == "http://schemas.google.com/g/2005#home" } } 

      describe '#address' do
        subject { super().address }
        it { is_expected.to eq("home@example.com") }
      end

      describe '#label' do
        subject { super().label }
        it { is_expected.to be_nil }
      end

      describe '#primary' do
        subject { super().primary }
        it { is_expected.to be_truthy }
      end
    end

    context "work_email" do
      subject { emails.find { |e| e.rel == "http://schemas.google.com/g/2005#work" } } 

      describe '#address' do
        subject { super().address }
        it { is_expected.to eq("work@example.com") }
      end

      describe '#label' do
        subject { super().label }
        it { is_expected.to be_nil }
      end

      describe '#primary' do
        subject { super().primary }
        it { is_expected.to be_falsey }
      end
    end

    context "other_email" do
      subject { emails.find { |e| e.rel == "http://schemas.google.com/g/2005#other" } } 

      describe '#address' do
        subject { super().address }
        it { is_expected.to eq("other@example.com") }
      end

      describe '#label' do
        subject { super().label }
        it { is_expected.to be_nil }
      end

      describe '#primary' do
        subject { super().primary }
        it { is_expected.to be_falsey }
      end
    end

    context "custom_email" do
      subject { emails.find { |e| e.rel.nil? } }

      describe '#address' do
        subject { super().address }
        it { is_expected.to eq("nonstandard@example.com") }
      end

      describe '#label' do
        subject { super().label }
        it { is_expected.to eq("Non standard") }
      end

      describe '#primary' do
        subject { super().primary }
        it { is_expected.to be_falsey }
      end
    end

  end

  context "should load phones from xml" do
    let (:phones) { GoogleR::Contact.from_xml(@doc_root).phones }
    subject { phones }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(4) }
    end

    context "home_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#home" } }

      describe '#text' do
        subject { super().text }
        it { is_expected.to eq("444-home") }
      end
    end

    context "work_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#work" } }

      describe '#text' do
        subject { super().text }
        it { is_expected.to eq("023-office") }
      end
    end

    context "mobile_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#mobile" } }

      describe '#text' do
        subject { super().text }
        it { is_expected.to eq("43-mobile") }
      end
    end

    context "main_phone" do
      subject { phones.find { |e| e.rel == "http://schemas.google.com/g/2005#main" } }

      describe '#text' do
        subject { super().text }
        it { is_expected.to eq("888-main") }
      end
    end
  end

  context "should load name from xml" do
    describe '#name_prefix' do
      subject { super().name_prefix }
      it { is_expected.to eq("Sir") }
    end

    describe '#given_name' do
      subject { super().given_name }
      it { is_expected.to eq("Mike") }
    end

    describe '#additional_name' do
      subject { super().additional_name }
      it { is_expected.to eq("Thomas") }
    end

    describe '#family_name' do
      subject { super().family_name }
      it { is_expected.to eq("Bugno") }
    end

    describe '#name_suffix' do
      subject { super().name_suffix }
      it { is_expected.to eq("XI") }
    end

    describe '#full_name' do
      subject { super().full_name }
      it { is_expected.to eq("Sir Mike Thomas Bugno XI") }
    end
  end

  context "should load content from xml" do
    describe '#content' do
      subject { super().content }
      it { is_expected.to eq("Notes about Mike") }
    end
  end

  context "should load updated from xml" do
    describe '#updated' do
      subject { super().updated }
      it { is_expected.to eq(Time.parse("2012-03-15T20:49:22.418Z")) }
    end
  end

  context "should load organisations from xml" do
    let (:organizations) { GoogleR::Contact.from_xml(@doc_root).organizations }
    subject { organizations }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(1) }
    end

    context "single organization" do
      let (:organization) { GoogleR::Contact.from_xml(@doc_root).organizations.first }
      subject { organization }

      describe '#rel' do
        subject { super().rel }
        it { is_expected.to eq("http://schemas.google.com/g/2005#other") }
      end

      describe '#name' do
        subject { super().name }
        it { is_expected.to eq("FutureSimple") }
      end

      describe '#title' do
        subject { super().title }
        it { is_expected.to eq("Coder") }
      end
    end
  end

  context "should load user nickname from xml" do
    describe '#nickname' do
      subject { super().nickname }
      it { should = "Majki"}
    end
  end

  context "should load addresses from xml" do
    let (:addresses) { GoogleR::Contact.from_xml(@doc_root).addresses }
    subject { addresses }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(2) }
    end

    context "home" do
      subject { addresses.find { |e| e.rel == "http://schemas.google.com/g/2005#home" } }

      describe '#street' do
        subject { super().street }
        it { is_expected.to eq("ulica") }
      end

      describe '#neighborhood' do
        subject { super().neighborhood }
        it { is_expected.to eq("okolica") }
      end

      describe '#pobox' do
        subject { super().pobox }
        it { is_expected.to eq("skrytka") }
      end

      describe '#postcode' do
        subject { super().postcode }
        it { is_expected.to eq("kod") }
      end

      describe '#city' do
        subject { super().city }
        it { is_expected.to eq("miasto") }
      end

      describe '#region' do
        subject { super().region }
        it { is_expected.to eq("wojewodztwo") }
      end

      describe '#country' do
        subject { super().country }
        it { is_expected.to eq("kraj") }
      end
    end

    context "work" do
      subject { addresses.find { |e| e.rel == "http://schemas.google.com/g/2005#work" } }

      describe '#street' do
        subject { super().street }
        it { is_expected.to eq("ulica2") }
      end

      describe '#neighborhood' do
        subject { super().neighborhood }
        it { is_expected.to eq("okolica2") }
      end

      describe '#pobox' do
        subject { super().pobox }
        it { is_expected.to eq("skrytka2") }
      end

      describe '#postcode' do
        subject { super().postcode }
        it { is_expected.to eq("kod2") }
      end

      describe '#city' do
        subject { super().city }
        it { is_expected.to eq("miasto2") }
      end

      describe '#region' do
        subject { super().region }
        it { is_expected.to eq("wojewodztwo2") }
      end

      describe '#country' do
        subject { super().country }
        it { is_expected.to eq("kraj2") }
      end
    end

  end

  context "should load group membership from xml" do
    let (:groups) { GoogleR::Contact.from_xml(@doc_root).groups }
    subject { groups }

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(2) }
    end

    context "first" do
      google_id = "http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/6"
      subject { groups.find { |e| e.google_id == google_id } }
      it { is_expected.not_to be_nil }
    end

    context "last" do
      google_id = "http://www.google.com/m8/feeds/groups/michal%40futuresimple.com/base/5747930b8e7844f6"
      subject { groups.find { |e| e.google_id == google_id } }
      it { is_expected.not_to be_nil }
    end
  end

  context "should treat contact without google_id as new?" do
    subject { GoogleR::Contact.new }
    it { is_expected.to be_new }
  end

  context "should treat contact with google_id as !new?" do
    it { is_expected.not_to be_new }
  end

  context "should load user fields from xml" do
    describe '#user_fields' do
      subject { super().user_fields }
      it { is_expected.to eq({"own key" => "Own value"}) }
    end
  end

  it "should load websites from xml" do
    expect(contact.websites.map { |e| e.href }.sort).to eq(["glowna.com", "sluzbowy.com"].sort)
    expect(contact.websites.map { |e| e.rel }.sort).to eq(["work", "home-page"].sort)
  end

  it "should generate valid xml" do
    xml = contact.to_google
    c = Nokogiri::XML.parse(xml)
    c = c.root

    expect(c.name).to eq("entry")
    expect(c.namespace.prefix).to eq("atom")

    expect(c.search("id").size).to eq(1)

    expect(c.search("./gd:name/gd:givenName").size).to eq(1)
    expect(c.search("./gd:name/gd:givenName").inner_text).to eq("Mike")
    expect(c.search("./gd:name/gd:additionalName").size).to eq(1)
    expect(c.search("./gd:name/gd:additionalName").inner_text).to eq("Thomas")
    expect(c.search("./gd:name/gd:familyName").size).to eq(1)
    expect(c.search("./gd:name/gd:familyName").inner_text).to eq("Bugno")
    expect(c.search("./gd:name/gd:namePrefix").size).to eq(1)
    expect(c.search("./gd:name/gd:namePrefix").inner_text).to eq("Sir")
    expect(c.search("./gd:name/gd:nameSuffix").size).to eq(1)
    expect(c.search("./gd:name/gd:nameSuffix").inner_text).to eq("XI")

    expect(c.search("./atom:content").inner_text).to eq("Notes about Mike")

    expect(c.search("./gContact:nickname").inner_text).to eq("Majki")

    expect(c.search("./gd:phoneNumber").map { |e| e.inner_text }.sort).to eq(["43-mobile", "023-office", "444-home", "888-main"].sort)

    expect(c.search("./gd:email").map { |e| e[:address] }).to eq(["home@example.com", "work@example.com", "other@example.com", "nonstandard@example.com"])
    expect(c.search("./gd:email").map { |e| e[:primary] }).to eq(["true", "false", "false", "false"])

    expect(c.search("./gd:organization/gd:orgName").size).to eq(1)
    expect(c.search("./gd:organization/gd:orgName").inner_text).to eq("FutureSimple")
    expect(c.search("./gd:organization/gd:orgTitle").size).to eq(1)
    expect(c.search("./gd:organization/gd:orgTitle").inner_text).to eq("Coder")

    expect(c.search("./gContact:groupMembershipInfo").size).to eq(2)
    expect(c.search("./gContact:groupMembershipInfo").map { |e| e[:deleted] }).to eq(["false", "false"])

    expect(c.search("./gContact:userDefinedField").size).to eq(1)
    expect(c.search("./gContact:userDefinedField")[0][:key]).to eq("own key")
    expect(c.search("./gContact:userDefinedField")[0][:value]).to eq("Own value")

    websites = c.search("./gContact:website")
    expect(websites.map { |e| e[:href] }.sort).to eq(["glowna.com", "sluzbowy.com"].sort)
    expect(websites.map { |e| e[:rel] }.sort).to eq(["work", "home-page"].sort)
  end

  context "google api expectations" do
    it "should send application/xml+atom content type for contacts" do
      headers = GoogleR::Contact.api_headers
      expect(headers).to have_key("Content-Type")
      expect(headers["Content-Type"]).to eq("application/atom+xml")
    end
  end
end
